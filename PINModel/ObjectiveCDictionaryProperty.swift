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
    var schemaLoader: SchemaLoader

    required init(descriptor: ObjectSchemaObjectProperty, className: String, schemaLoader: SchemaLoader) {
        self.propertyDescriptor = descriptor
        self.className = className
        self.schemaLoader = schemaLoader
        // TODO: Cache ObjectiveCProperty representation of additionalProperties here rather than every method.
    }

    func renderEncodeWithCoderStatement() -> String {
        // This might be unnecessary if the base class does the same thing.
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        // - (id)decodeObjectOfClasses:(NSSet *)classes forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
        var deserializationClasses = Set([NSStringFromClass(NSDictionary), NSStringFromClass(NSString)])

        switch self.propertyDescriptor.additionalProperties {
        case let d as ObjectSchemaPolymorphicProperty:
            let prop = ObjectiveCPolymorphicProperty(descriptor: d, className: self.className, schemaLoader: self.schemaLoader)
            deserializationClasses.unionInPlace(prop.classList())
        default:
            if let valueTypes = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
                let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className, schemaLoader: self.schemaLoader)
                deserializationClasses.insert(prop.objectiveCStringForJSONType())
            }
        }

        let classList = deserializationClasses.map { "[\($0) class]" }.joinWithSeparator(", ")
        return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        var requiresAssignmentLogic = false
        if let additionalProperties = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(additionalProperties, className: self.className, schemaLoader: self.schemaLoader)
            assert(prop.isScalarType() == false, "Dictionaries cannot contain primitive types")
            requiresAssignmentLogic = prop.propertyRequiresAssignmentLogic()
        }
        return requiresAssignmentLogic
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        // This might be unnecessary if the base class does the same thing.
        return propertyVariableString
    }

    func objectiveCStringForJSONType() -> String {
        if let valueTypes = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className, schemaLoader: self.schemaLoader)
            return "\(NSStringFromClass(NSDictionary)) <\(NSStringFromClass(NSString)) *, \(prop.objectiveCStringForJSONType()) *>"
        }

        return "\(NSStringFromClass(NSDictionary)) <\(NSStringFromClass(NSString)) *, __kindof \(NSStringFromClass(NSObject)) *>"
    }


    func templatedPropertyAssignmentStatementFromDictionary(assigneeName: String, className: String) -> [String] {
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)
        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(assigneeName) = \(shortPropFromDictionary);"]
        }


        switch self.propertyDescriptor.additionalProperties {

        case let additionalProperties as ObjectSchemaPolymorphicProperty:
            let prop = ObjectiveCPolymorphicProperty(descriptor: additionalProperties, className: self.className, schemaLoader: self.schemaLoader)
            if prop.propertyRequiresAssignmentLogic() {
                return [
                    "NSDictionary *items = value;",
                    "NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:items.count];",
                    "[items enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, __unused BOOL *stop) {",
                    "    if (obj != nil && [obj isEqual:[NSNull null]] == NO) {"] +
                    prop.templatedPropertyAssignmentStatementFromDictionary("result[key]",
                        className: className, dictionaryElementName: "obj").map { "        " + $0 } +
                    ["    }",
                    "}];",
                    "\(assigneeName) = result;"]
            }
        default:
            if let additionalProperties = self.propertyDescriptor.additionalProperties as ObjectSchemaProperty? {
                let prop = PropertyFactory.propertyForDescriptor(additionalProperties, className: self.className, schemaLoader: self.schemaLoader)
                let deserializedObject = prop.propertyStatementFromDictionary("obj", className: className)
                if prop.propertyRequiresAssignmentLogic() {
                    return [
                        "NSDictionary *items = value;",
                        "NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:items.count];",
                        "[items enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, __unused BOOL *stop) {",
                        "    if (obj != nil && [obj isEqual:[NSNull null]] == NO) {",
                        "        result[key] = \(deserializedObject);",
                        "    }",
                        "}];",
                        "\(assigneeName) = result;"
                    ]
                }
            }
        }

        let propertyAssignmentStatement = "\(assigneeName) = \(propFromDictionary);"
        return [propertyAssignmentStatement]
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return self.templatedPropertyAssignmentStatementFromDictionary("_\(formattedPropName)", className: className)
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return self.templatedPropertyAssignmentStatementFromDictionary("\(originVariableString).\(formattedPropName)", className: className)
    }

}
