//
//  ObjectiveCClassProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 1/5/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation

final class ObjectiveCClassProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaPointerProperty
    var className: String
    var resolvedSchema: ObjectSchemaObjectProperty
    var schemaLoader: SchemaLoader
    
    required init(descriptor: ObjectSchemaPointerProperty, className: String, schemaLoader: SchemaLoader) {
        self.propertyDescriptor = descriptor
        self.className = className
        let subclass = self.propertyDescriptor
        self.schemaLoader = schemaLoader
        if let schema = self.schemaLoader.loadSchema(subclass.ref) as? ObjectSchemaObjectProperty {
            self.resolvedSchema = schema
        } else {
            assert(false, "Unable to load schema: \(subclass.ref))")
            self.resolvedSchema =  self.schemaLoader.loadSchema(subclass.ref) as! ObjectSchemaObjectProperty
        }
    }

    func polymorphicTypeIdentifier() -> String {
        return self.resolvedSchema.name
    }

    func renderDecodeWithCoderStatement() -> String {
        // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
        // https://phabricator.pinadmin.com/T46
        let className = ObjectiveCInterfaceFileDescriptor(descriptor: self.resolvedSchema, generatorParameters: [GenerationParameterType.ClassPrefix: "PI"], parentDescriptor: nil, schemaLoader: self.schemaLoader).className
        return "[aDecoder decodeObjectOfClass:[\(className) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return true
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        if let schema = self.schemaLoader.loadSchema(self.propertyDescriptor.ref) {
            var classNameForSchema = ""
            // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
            var generationParameters =  [GenerationParameterType.ClassPrefix: "PI"]
            if let classPrefix = generationParameters[GenerationParameterType.ClassPrefix] as String? {
                classNameForSchema = String(format: "%@%@", arguments: [
                    classPrefix,
                    schema.name.snakeCaseToCamelCase()
                    ])
            } else {
                classNameForSchema = schema.name.snakeCaseToCamelCase()
            }

            return "[[\(classNameForSchema) alloc] initWithDictionary:\(propertyVariableString)]"
        }
        assert(false, "Failed to load schema for class")
        return ""
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {
        // Likely this is going to just be in the base class so we can remove later...
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
        // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
        // https://phabricator.pinadmin.com/T46
        return ObjectiveCInterfaceFileDescriptor(descriptor: self.resolvedSchema, generatorParameters: [GenerationParameterType.ClassPrefix: "PI"], parentDescriptor: nil, schemaLoader: self.schemaLoader).className
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        let subclass = PropertyFactory.propertyForDescriptor(self.propertyDescriptor, className: self.className, schemaLoader: self.schemaLoader)
        let propStmt = subclass.propertyStatementFromDictionary("value", className: className)
        return [
            "if (\(originVariableString).\(formattedPropName) != nil) {",
            "   \(originVariableString).\(formattedPropName) = [\(originVariableString).\(formattedPropName) mergeWithDictionary:value];",
            "} else {",
            "   \(originVariableString).\(formattedPropName) = \(propStmt);",
            "}"
        ]
    }

}
