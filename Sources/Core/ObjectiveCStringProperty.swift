////
////  ObjectiveCStringProperty.swift
////  pinmodel
////
////  Created by Rahul Malik on 12/28/15.
////  Copyright © 2015 Rahul Malik. All rights reserved.
////
//
//import Foundation
//
//
//final class ObjectiveCStringProperty: ObjectiveCProperty {
//
//    var propertyDescriptor: ObjectSchemaStringProperty
//    var className: String
//    var schemaLoader: SchemaLoader
//
//    required init(descriptor: ObjectSchemaStringProperty, className: String, schemaLoader: SchemaLoader) {
//        self.propertyDescriptor = descriptor
//        self.className = className
//        self.schemaLoader = schemaLoader
//    }
//
//    func renderEnumUtilityMethodsInterface() -> String {
//        // Should this be an override? This only occurs for strings right now.
//        return ["extern \(self.enumPropertyTypeName()) \(self.enumPropertyTypeName())FromString(NSString * _Nonnull str);",
//                "extern NSString * _Nonnull \(self.enumPropertyTypeName())ToString(\(self.enumPropertyTypeName()) enumType);"].joined(separator: "\n")
//    }
//
//    func renderEnumDeclaration() -> String {
//        assert(self.isEnumPropertyType()) // Replace with "guard" statement?
//
//        let indent = "    "
//        let enumTypeValues = self.propertyDescriptor.enumValues.enumerated().map({ (index: Int, val: EnumValue<AnyObject>) -> String in
//            let description = val.description
//            let defaultVal = val.defaultValue as! String
//
//            let enumValueName = self.enumPropertyTypeName() + description.snakeCaseToCamelCase()
//            return indent + "\(enumValueName) /* \(defaultVal) */"
//        })
//        return ["typedef NS_ENUM(NSInteger, \(self.enumPropertyTypeName())) {",
//            enumTypeValues.joined(separator: ",\n"),
//            "};"].joined(separator: "\n")
//    }
//
//    func renderEncodeWithCoderStatement() -> String {
//        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
//        if self.isEnumPropertyType() {
//            return "[aCoder encodeInteger:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
//        }
//        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
//    }
//
//    func renderDecodeWithCoderStatement() -> String {
//        if self.isEnumPropertyType() {
//            return "[aDecoder decodeIntegerForKey:@\"\(self.propertyDescriptor.name)\"]"
//        }
//        return "[aDecoder decodeObjectOfClass:[\(self.objectiveCStringForJSONType()) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
//    }
//
//    func propertyRequiresAssignmentLogic() -> Bool {
//        return (self.propertyDescriptor.format == StringFormatType.Uri ||
//                self.propertyDescriptor.format == StringFormatType.DateTime)
//    }
//
//    func propertyStatementFromDictionary(_ propertyVariableString: String, className: String) -> String {
//        if self.isEnumPropertyType() {
//            return "\(self.enumPropertyTypeName())FromString(\(propertyVariableString))"
//        }
//
//        var statement = propertyVariableString
//        switch self.propertyDescriptor.format {
//        case .some(StringFormatType.Uri):
//            statement = "[NSURL URLWithString:\(propertyVariableString)]"
//        case .some(StringFormatType.DateTime):
//            statement = "[[NSValueTransformer valueTransformerForName:\(DateValueTransformerKey)] transformedValue:\(propertyVariableString)]"
//        case .some(_), .none:
//            statement = propertyVariableString
//        }
//
//        return statement
//    }
//
//    func propertyAssignmentStatementFromDictionary(_ className: String) -> [String] {
//
//        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
//        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)
//
//        if self.propertyRequiresAssignmentLogic() == false {
//            // Code optimization: Early-exit if we are simply doing a basic assignment
//            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
//            return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
//        }
//
//        return ["_\(formattedPropName) = \(propFromDictionary);"]
//    }
//
//    func objectiveCStringForJSONType() -> String {
//        // If this is a string enum, we will return the enumeration type name (which is represented as an int enum).
//        if self.isEnumPropertyType() {
//            return self.enumPropertyTypeName()
//        }
//
//        switch self.propertyDescriptor.format {
//        case .some(StringFormatType.Uri) :
//            return NSURL.className()
//        case .some(StringFormatType.DateTime):
//            return NSDate.className()
//        default:
//            return NSString.className()
//        }
//    }
//
//}
