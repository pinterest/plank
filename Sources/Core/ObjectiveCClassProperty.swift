////
////  ObjectiveCClassProperty.swift
////  pinmodel
////
////  Created by Rahul Malik on 1/5/16.
////  Copyright © 2016 Rahul Malik. All rights reserved.
////
//
//import Foundation
//
//final class ObjectiveCClassProperty: ObjectiveCProperty {
//
//    var propertyDescriptor: ObjectSchemaPointerProperty
//    var className: String
//    var resolvedSchema: ObjectSchemaObjectProperty
//    let parentProperty: ObjectSchemaObjectProperty?
//    var schemaLoader: SchemaLoader
//    
//    required init(descriptor: ObjectSchemaPointerProperty, className: String, schemaLoader: SchemaLoader) {
//        self.propertyDescriptor = descriptor
//        self.className = className
//        let subclass = self.propertyDescriptor
//        self.schemaLoader = schemaLoader
//        if let schema = self.schemaLoader.loadSchema(subclass.ref) as? ObjectSchemaObjectProperty {
//            self.resolvedSchema = schema
//        } else {
//            assert(false, "Unable to load schema: \(subclass.ref))")
//            self.resolvedSchema =  self.schemaLoader.loadSchema(subclass.ref) as! ObjectSchemaObjectProperty
//        }
//
//        if let parentSchema = self.resolvedSchema.extends {
//            self.parentProperty = self.schemaLoader.loadSchema(parentSchema.ref) as? ObjectSchemaObjectProperty
//        } else {
//            self.parentProperty = nil
//        }
//    }
//
//    func polymorphicTypeIdentifier() -> String {
//        return self.resolvedSchema.algebraicDataTypeIdentifier
//    }
//
//    func renderDecodeWithCoderStatement() -> String {
//        // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
//        // https://phabricator.pinadmin.com/T46
//        let className = ObjectiveCInterfaceFileDescriptor(descriptor: self.resolvedSchema, generatorParameters: [GenerationParameterType.classPrefix: "PI"], parentDescriptor: self.parentProperty, schemaLoader: self.schemaLoader).className
//        return "[aDecoder decodeObjectOfClass:[\(className) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
//    }
//
//    func propertyRequiresAssignmentLogic() -> Bool {
//        return true
//    }
//
//    func propertyStatementFromDictionary(_ propertyVariableString: String, className: String) -> String {
//        if let schema = self.schemaLoader.loadSchema(self.propertyDescriptor.ref) {
//            var classNameForSchema = ""
//            // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
//            var generationParameters =  [GenerationParameterType.classPrefix: "PI"]
//            if let classPrefix = generationParameters[GenerationParameterType.classPrefix] as String? {
//                classNameForSchema = "\(classPrefix)\(schema.name.snakeCaseToCamelCase())"
//            } else {
//                classNameForSchema = schema.name.snakeCaseToCamelCase()
//            }
//
//            return "[[\(classNameForSchema) alloc] initWithDictionary:\(propertyVariableString)]"
//        }
//        assert(false, "Failed to load schema for class")
//        return ""
//    }
//
//    func propertyAssignmentStatementFromDictionary(_ className: String) -> [String] {
//        // Likely this is going to just be in the base class so we can remove later...
//        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
//        let propFromDictionary = self.propertyStatementFromDictionary("value", className: className)
//
//        if self.propertyRequiresAssignmentLogic() == false {
//            // Code optimization: Early-exit if we are simply doing a basic assignment
//            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
//            return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
//        }
//
//        let propertyAssignmentStatement = "_\(formattedPropName) = \(propFromDictionary);"
//        return [propertyAssignmentStatement]
//    }
//
//    func objectiveCStringForJSONType() -> String {
//        // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
//        // https://phabricator.pinadmin.com/T46
//        return ObjectiveCInterfaceFileDescriptor(descriptor: self.resolvedSchema, generatorParameters: [GenerationParameterType.classPrefix: "PI"], parentDescriptor: self.parentProperty, schemaLoader: self.schemaLoader).className
//    }
//
//}
