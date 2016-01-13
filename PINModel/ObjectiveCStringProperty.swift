//
//  ObjectiveCStringProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 12/28/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

let DateValueTransformerKey = "kPINModelDateValueTransformerKey"

final class ObjectiveCStringProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaStringProperty
    var className: String

    required init(descriptor: ObjectSchemaStringProperty, className: String) {
        self.propertyDescriptor = descriptor
        self.className = className
    }

    func renderEnumUtilityMethodsInterface() -> String {
        // Should this be an override? This only occurs for strings right now.
        return ["extern \(self.enumPropertyTypeName()) \(self.enumPropertyTypeName())FromString(NSString * _Nonnull str);",
                "extern NSString * _Nonnull \(self.enumPropertyTypeName())ToString(\(self.enumPropertyTypeName()) enumType);"].joinWithSeparator("\n")
    }

    func renderEnumDeclaration() -> String {
        assert(self.isEnumPropertyType()) // Replace with "guard" statement?

        let indent = "    "
        let enumTypeValues = self.propertyDescriptor.enumValues.enumerate().map({ (index: Int, val: JSONObject) -> String in
            let description = val["description"] as! String
            let defaultVal = val["default"] as! String

            let enumValueName = self.enumPropertyTypeName() + description.snakeCaseToCamelCase()
            return indent + "\(enumValueName) /* \(defaultVal) */"
        })
        return ["typedef NS_ENUM(NSInteger, \(self.enumPropertyTypeName())) {",
            enumTypeValues.joinWithSeparator(",\n"),
            "};"].joinWithSeparator("\n")
    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        if self.isEnumPropertyType() {
            return "[aCoder encodeInteger:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
        }
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        if self.isEnumPropertyType() {
            return "[aDecoder decodeIntegerForKey:@\"\(self.propertyDescriptor.name)\"]"
        }
        return "[aDecoder decodeObjectOfClass:[\(self.objectiveCStringForJSONType()) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return (self.propertyDescriptor.format == JSONStringFormatType.Uri ||
                self.propertyDescriptor.format == JSONStringFormatType.DateTime)
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        if self.isEnumPropertyType() {
            return "\(self.enumPropertyTypeName())FromString(\(propertyVariableString))"
        }

        var statement = propertyVariableString
        switch self.propertyDescriptor.format {
        case .Some(JSONStringFormatType.Uri):
            statement = "[NSURL URLWithString:\(propertyVariableString)]"
        case .Some(JSONStringFormatType.DateTime):
            statement = "[[NSValueTransformer valueTransformerForName:\(DateValueTransformerKey)] transformedValue:\(propertyVariableString)]"
        case .Some(_), .None:
            statement = propertyVariableString
        }

        return statement
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {

        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        return ["_\(formattedPropName) = \(propFromDictionary);"]
    }

    func objectiveCStringForJSONType() -> String {
        // If this is a string enum, we will return the enumeration type name (which is represented as an int enum).
        if self.isEnumPropertyType() {
            return self.enumPropertyTypeName()
        }

        switch self.propertyDescriptor.format {
        case .Some(JSONStringFormatType.Uri) :
            return NSStringFromClass(NSURL)
        case .Some(JSONStringFormatType.DateTime):
            return NSStringFromClass(NSDate)
        default:
            return NSStringFromClass(NSString)
        }
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        // This is pretty general and will likely be the same as the base class, might want to figure this one out..
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)
        return ["\(originVariableString).\(formattedPropName) = \(propFromDictionary);"]
    }
}
