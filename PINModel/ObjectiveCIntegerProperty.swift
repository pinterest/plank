//
//  ObjectiveCIntegerProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 12/28/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

final class ObjectiveCIntegerProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaNumberProperty
    var className: String

    required init(descriptor: ObjectSchemaNumberProperty, className: String) {
        self.propertyDescriptor = descriptor
        self.className = className
    }

    func renderEnumDeclaration() -> String {
        assert(self.isEnumPropertyType())

        let indent = "    "
        let enumTypeValues = self.propertyDescriptor.enumValues.map({ (val: JSONObject) -> String in
            let description = val["description"] as! String
            let defaultVal = val["default"] as! Int
            let enumValueName = self.enumPropertyTypeName() + description.snakeCaseToCamelCase()
            return indent + "\(enumValueName) = \(defaultVal)"
        })
        return ["typedef NS_ENUM(NSInteger, \(self.enumPropertyTypeName())) {",
            enumTypeValues.joinWithSeparator(",\n"),
            "};"].joinWithSeparator("\n")
    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        if self.propertyDescriptor.jsonType == JSONType.Number {
            return "[aCoder encodeCGFloat:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
        }
        return "[aCoder encodeInteger:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        if self.propertyDescriptor.jsonType == JSONType.Number {
            return "[aDecoder decodeCGFloatForKey:@\"\(self.propertyDescriptor.name)\"]"
        }
        return "[aDecoder decodeIntegerForKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        if self.propertyDescriptor.jsonType == JSONType.Number {
            return "[\(propertyVariableString) floatValue]"
        }
       return "[\(propertyVariableString) integerValue]"
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {
        // this likely does not need to be overridden
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        let propertyAssignmentStatement = "_\(formattedPropName) = \(propFromDictionary);"
        return [propertyAssignmentStatement]
    }

    func objectiveCStringForJSONType() -> String {
        if self.isEnumPropertyType() {
            return self.enumPropertyTypeName()
        }

        if self.propertyDescriptor.jsonType == JSONType.Number {
            return ObjCPrimitiveType.Float.rawValue
        }

        return ObjCPrimitiveType.Integer.rawValue
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        // this likely does not need to be overridden
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        let propertyAssignmentStatement = "\(originVariableString).\(formattedPropName) = \(propFromDictionary);"
        return [propertyAssignmentStatement]
    }
}
