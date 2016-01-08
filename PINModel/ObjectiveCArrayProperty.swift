//
//  ObjectiveCArrayProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 12/28/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

final class ObjectiveCArrayProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaArrayProperty
    var className: String

    required init(descriptor: ObjectSchemaArrayProperty, className: String) {
        self.propertyDescriptor = descriptor
        self.className = className
    }

    func renderEncodeWithCoderStatement() -> String {
        // Potentially remove since this is the default case logic and could be located in the superclass.
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        // - (id)decodeObjectOfClasses:(NSSet *)classes forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
        var deserializationClasses = Set([NSStringFromClass(NSArray)])
        if let valueTypes = self.propertyDescriptor.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className)
            deserializationClasses.insert(prop.objectiveCStringForJSONType())
        }
        let classList = deserializationClasses.map { "[\($0) class]" }.joinWithSeparator(", ")
        return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        var requiresAssignmentLogic = false
        if let arrayItems = self.propertyDescriptor.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(arrayItems, className: self.className)
            assert(prop.isScalarType() == false) // Arrays cannot contain primitive types
            requiresAssignmentLogic = prop.propertyRequiresAssignmentLogic()
        }
        return requiresAssignmentLogic
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        // Potentially remove since this is the default case logic and could be located in the superclass.
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

        let propertyAssignmentStatement = "_\(formattedPropName) = \(propFromDictionary);"

        let subclass = self.propertyDescriptor
        if let arrayItems = subclass.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(arrayItems, className: self.className)
            assert(prop.isScalarType() == false) // Arrays cannot contain primitive types
            if arrayItems.jsonType == JSONType.Pointer ||
                (arrayItems.jsonType == JSONType.String && (arrayItems as! ObjectSchemaStringProperty).format == JSONStringFormatType.Uri) {
                    let deserializedObject = prop.propertyStatementFromDictionary("obj", className: className)
                    return [
                        "NSArray *items = value;",
                        "NSMutableArray *result = [NSMutableArray arrayWithCapacity:items.count];",
                        "for (id obj in items) {",
                        "    if (obj != nil && [obj isEqual:[NSNull null]] == NO) {",
                        "        [result addObject:\(deserializedObject)];",
                        "    }",
                        "}",
                        "_\(formattedPropName) = result;"
                    ]

            }
        }
        return [propertyAssignmentStatement]
    }

    func objectiveCStringForJSONType() -> String {
        let subclass = self.propertyDescriptor
        if let valueTypes = subclass.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className)
            return "\(NSStringFromClass(NSArray)) <\(prop.objectiveCStringForJSONType()) *>"
        }
        return NSStringFromClass(NSArray)
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        let propertyAssignmentStatement = "\(originVariableString).\(formattedPropName) = \(propFromDictionary);"

        let subclass = self.propertyDescriptor
        if let arrayItems = subclass.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(arrayItems, className: self.className)
            assert(prop.isScalarType() == false) // Arrays cannot contain primitive types
            if arrayItems.jsonType == JSONType.Pointer ||
                (arrayItems.jsonType == JSONType.String && (arrayItems as! ObjectSchemaStringProperty).format == JSONStringFormatType.Uri) {
                    let deserializedObject = prop.propertyStatementFromDictionary("obj", className: className)
                    return [
                        "NSArray *items = value;",
                        "NSMutableArray *result = [NSMutableArray arrayWithCapacity:items.count];",
                        "for (id obj in items) {",
                        "    [result addObject:\(deserializedObject)];",
                        "}",
                        "\(originVariableString).\(formattedPropName) = result;"
                    ]
            }
        }
        return [propertyAssignmentStatement]
    }

}
