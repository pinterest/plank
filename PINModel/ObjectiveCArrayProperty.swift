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
    var schemaLoader: SchemaLoader

    required init(descriptor: ObjectSchemaArrayProperty, className: String, schemaLoader: SchemaLoader) {
        self.propertyDescriptor = descriptor
        self.className = className
        self.schemaLoader = schemaLoader
    }

    func renderEncodeWithCoderStatement() -> String {
        // Potentially remove since this is the default case logic and could be located in the superclass.
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        var deserializationClasses = Set([NSArray.className()])

        switch self.propertyDescriptor.items {
        case let d as ObjectSchemaPolymorphicProperty:
            let prop = ObjectiveCPolymorphicProperty(descriptor: d, className: self.className, schemaLoader: self.schemaLoader)
            deserializationClasses.formUnion(prop.classList())
        default:
            if let valueTypes = self.propertyDescriptor.items as ObjectSchemaProperty? {
                let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className, schemaLoader: self.schemaLoader)
                deserializationClasses.insert(prop.objectiveCStringForJSONType())
            }
        }

        let classList = deserializationClasses.map { "[\($0) class]" }.joined(separator: ", ")
        return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        var requiresAssignmentLogic = false
        if let arrayItems = self.propertyDescriptor.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(arrayItems, className: self.className, schemaLoader: self.schemaLoader)
            assert(prop.isScalarType() == false) // Arrays cannot contain primitive types
            requiresAssignmentLogic = prop.propertyRequiresAssignmentLogic()
        }
        return requiresAssignmentLogic
    }

    func propertyStatementFromDictionary(_ propertyVariableString: String, className: String) -> String {
        // Potentially remove since this is the default case logic and could be located in the superclass.
        return propertyVariableString
    }


    func objectiveCStringForJSONType() -> String {
        let subclass = self.propertyDescriptor
        if let valueTypes = subclass.items as ObjectSchemaProperty? {
            let prop = PropertyFactory.propertyForDescriptor(valueTypes, className: self.className, schemaLoader: self.schemaLoader)
            return "\(NSArray.className()) <\(prop.objectiveCStringForJSONType()) *>"
        }
        return NSArray.className()
    }

    func templatedPropertyAssignmentStatementFromDictionary(_ assigneeName: String, className: String) -> [String] {
        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(assigneeName) = \(shortPropFromDictionary);"]
        }

        switch self.propertyDescriptor.items {
        case let arrayItems as ObjectSchemaPolymorphicProperty:
            let prop = ObjectiveCPolymorphicProperty(descriptor: arrayItems, className: self.className, schemaLoader: self.schemaLoader)
            return [
                 "NSArray *items = value;",
                 "NSMutableArray *result = [NSMutableArray arrayWithCapacity:items.count];",
                 "for (id obj in items) {",
                 "    if ([obj isEqual:[NSNull null]] == NO) {",
                 "        id parsedObj;"] +
                prop.templatedPropertyAssignmentStatementFromDictionary("parsedObj", className: className, dictionaryElementName: "obj").map {"        " + $0} +
                ["        if (parsedObj != nil) { [result addObject:parsedObj]; }",
                 "    }",
                 "}",
                 "\(assigneeName) = result;"
            ]
        default:
            if let arrayItems = self.propertyDescriptor.items as ObjectSchemaProperty? {
                let prop = PropertyFactory.propertyForDescriptor(arrayItems, className: self.className, schemaLoader: self.schemaLoader)
                assert(prop.isScalarType() == false) // Arrays cannot contain primitive types
                if prop.propertyRequiresAssignmentLogic() {
                    let deserializedObject = prop.propertyStatementFromDictionary("obj", className: className)
                    return [
                        "NSArray *items = value;",
                        "NSMutableArray *result = [NSMutableArray arrayWithCapacity:items.count];",
                        "for (id obj in items) {",
                        "    if ([obj isEqual:[NSNull null]] == NO) {",
                        "        [result addObject:\(deserializedObject)];",
                        "    }",
                        "}",
                        "\(assigneeName) = result;"
                    ]
                }
            }
        }

        let propertyAssignmentStatement = "\(assigneeName) = \(propFromDictionary);"
        return [propertyAssignmentStatement]
    }

    func propertyAssignmentStatementFromDictionary(_ className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return self.templatedPropertyAssignmentStatementFromDictionary( "_\(formattedPropName)", className: className)
    }

    func propertyMergeStatementFromDictionary(_ originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return self.templatedPropertyAssignmentStatementFromDictionary("\(originVariableString).\(formattedPropName)", className: className)
    }
}
