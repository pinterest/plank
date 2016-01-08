//
//  ObjectiveCObjectProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 12/28/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

final class ObjectiveCDictionaryProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaObjectProperty
    var className: String

    required init(descriptor: ObjectSchemaObjectProperty, className: String) {
        self.propertyDescriptor = descriptor
        self.className = className
    }

    func renderEncodeWithCoderStatement() -> String {
        // This might be unnecessary if the base class does the same thing.
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        // - (id)decodeObjectOfClasses:(NSSet *)classes forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
        NSStringFromClass(NSString)
        var deserializationClasses = Set([NSStringFromClass(NSDictionary), NSStringFromClass(NSString)])
        if let valueTypes = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className)
            deserializationClasses.insert(prop.objectiveCStringForJSONType())
        }
        let classList = deserializationClasses.map { "[\($0) class]" }.joinWithSeparator(", ")
        return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        var requiresAssignmentLogic = false
        if let additionalProperties = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(additionalProperties, className: self.className)
            assert(prop.isScalarType() == false) // Dictionaries cannot contain primitive types
            requiresAssignmentLogic = prop.propertyRequiresAssignmentLogic()
        }
        return requiresAssignmentLogic
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        // This might be unnecessary if the base class does the same thing.
        return propertyVariableString
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {

        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        if let additionalProperties = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(additionalProperties, className: self.className)
            assert(prop.isScalarType() == false) // Dictionaries cannot contain primitive types
            if additionalProperties.jsonType == JSONType.Pointer {
                let deserializedObject = prop.propertyStatementFromDictionary("obj", className: className)
                return [
                    "NSDictionary *items = value;",
                    "NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:items.count];",
                    "[items enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {",
                    "    if (obj != nil && [obj isEqual:[NSNull null]] == NO) {",
                    "        result[key] = \(deserializedObject);",
                    "    }",
                    "}];",
                    "_\(formattedPropName) = result;"
                ]
            }
        }

        let propertyAssignmentStatement = "_\(formattedPropName) = \(propFromDictionary);"
        return [propertyAssignmentStatement]
    }

    func objectiveCStringForJSONType() -> String {
        if let valueTypes = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className)
            return "\(NSStringFromClass(NSDictionary)) <\(NSStringFromClass(NSString)) *, \(prop.objectiveCStringForJSONType()) *>"
        }

        return "\(NSStringFromClass(NSDictionary)) <\(NSStringFromClass(NSString)) *, __kindof \(NSStringFromClass(NSObject)) *>"
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()

        if let additionalProperties = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(additionalProperties, className: self.className)

            assert(prop.isScalarType() == false) // Dictionaries cannot contain primitive types
            if additionalProperties.jsonType == JSONType.Pointer {
                let deserializedObject = prop.propertyStatementFromDictionary("obj", className: className)
                return [
                    "NSDictionary *items = value;",
                    "NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:items.count];",
                    "[items enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, __unused BOOL *stop) {",
                    "    result[key] = \(deserializedObject);",
                    "}];",
                    "\(originVariableString).\(formattedPropName) = result;"
                ]
            }
        }

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
