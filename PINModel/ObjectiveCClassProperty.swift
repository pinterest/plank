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

    required init(descriptor: ObjectSchemaPointerProperty, className: String) {
        self.propertyDescriptor = descriptor
        self.className = className
    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        // This function is pretty ugly.

        //- (id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
        let subclass = self.propertyDescriptor
        if let schema = SchemaLoader.sharedInstance.loadSchema(subclass.ref) as? ObjectSchemaObjectProperty {
            // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
            // https://phabricator.pinadmin.com/T46
            let className = ObjectiveCInterfaceFileDescriptor(descriptor: schema, generatorParameters: [GenerationParameterType.ClassPrefix: "PI"], parentDescriptor: nil).className
            return "[aDecoder decodeObjectOfClass:[\(className) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
        }

        // Failed to load schema
        assert(false)
        return ""
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return true
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        if let schema = SchemaLoader.sharedInstance.loadSchema(self.propertyDescriptor.ref) {
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
        if let schema = SchemaLoader.sharedInstance.loadSchema(self.propertyDescriptor.ref) as? ObjectSchemaObjectProperty {
            // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
            // https://phabricator.pinadmin.com/T46
            return ObjectiveCInterfaceFileDescriptor(descriptor: schema, generatorParameters: [GenerationParameterType.ClassPrefix: "PI"], parentDescriptor: nil).className
        } else {
            assert(false, "Failed to load schema")
            return ""
        }
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
            return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        let subclass = PropertyFactory.propertyForDescriptor(self.propertyDescriptor, className: self.className)
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
