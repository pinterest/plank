//
//  ObjCProperty.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

// MARK: Objective-C Helpers

public enum ObjCMemoryAssignmentType: String {
    case Copy = "copy"
    case Strong = "strong"
    case Weak = "weak"
    case Assign = "assign"
}

public enum ObjCAtomicityType: String {
    case Atomic = "atomic"
    case NonAtomic = "nonatomic"
}

public enum ObjCMutabilityType: String {
    case ReadOnly = "readonly"
    case ReadWrite = "readwrite"
}


extension ObjectSchemaProperty {
    func objectiveCStringForJSONType() -> String {
        switch self.jsonType {
        case .String :
            if self is ObjectSchemaStringProperty {
                let subclass = self as! ObjectSchemaStringProperty
                if subclass.format == JSONStringFormatType.Uri {
                    return NSStringFromClass(NSURL)
                }
            }
            return NSStringFromClass(NSString)
        case .Number :
            return "CGFloat"
        case .Integer :
            return "NSInteger"
        case .Boolean:
            return "BOOL"
        case .Array:
            if self is ObjectSchemaArrayProperty {
                let subclass = self as! ObjectSchemaArrayProperty
                if let valueTypes = subclass.items as ObjectSchemaProperty? {
                    return "\(NSStringFromClass(NSArray)) PI_GENERIC(\(valueTypes.objectiveCStringForJSONType()) *)"
                }
            }
            return NSStringFromClass(NSArray)
        case .Object:
            if self is ObjectSchemaObjectProperty {
                let subclass = self as! ObjectSchemaObjectProperty
                if let valueTypes = subclass.additionalProperties as ObjectSchemaProperty? {
                    return "\(NSStringFromClass(NSDictionary)) PI_GENERIC(\(NSStringFromClass(NSString)) *, \(valueTypes.objectiveCStringForJSONType()) *)"
                }
            }
            return NSStringFromClass(NSDictionary)
        case .Pointer:
            let subclass = self as! ObjectSchemaPointerProperty
            if let schema = SchemaLoader.sharedInstance.loadSchema(subclass.ref) as? ObjectSchemaObjectProperty {
                // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
                return ObjectiveCInterfaceFileDescriptor(descriptor: schema, generatorParameters: [GenerationParameterType.ClassPrefix : "PI"]).className
            } else {
                assert(false)
                return ""
            }


        default:
            return ""
        }
    }


    func propertyStatementFromDictionary(propertyVariableString : String) -> String {
        var statement = propertyVariableString
        switch self.jsonType {
        case .String :
            if self is ObjectSchemaStringProperty {
                let subclass = self as! ObjectSchemaStringProperty
                if subclass.format == JSONStringFormatType.Uri {
                    statement = "[NSURL URLWithString:\(propertyVariableString)]"
                }
            }
        case .Number :
            statement = "[\(propertyVariableString) floatValue]"
        case .Integer :
            statement = "[\(propertyVariableString) integerValue]"
        case .Boolean:
            statement = "[\(propertyVariableString) boolValue]"
        case .Pointer:
            let subclass = self as! ObjectSchemaPointerProperty
            if let schema = SchemaLoader.sharedInstance.loadSchema(subclass.ref) {
                var classNameForSchema = ""
                // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
                var generationParameters =  [GenerationParameterType.ClassPrefix : "PI"]
                if let classPrefix = generationParameters[GenerationParameterType.ClassPrefix] as String? {
                    classNameForSchema = String(format: "%@%@", arguments: [
                        classPrefix,
                        schema.name.snakeCaseToCamelCase()
                        ])
                } else {
                    classNameForSchema = schema.name.snakeCaseToCamelCase()
                }

                statement = "[[\(classNameForSchema) alloc] initWithDictionary:\(propertyVariableString)]"
            } else {
                assert(false)
            }

        default:
            statement = propertyVariableString
        }
        return statement
    }

    func propertyAssignmentStatementFromDictionary() -> [String] {
        let formattedPropName = self.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value")

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.name)\")")
            return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
        }

        var propertyAssignmentStatement = "_\(formattedPropName) = \(propFromDictionary);"
        switch self.jsonType {
        case .Array :
            let subclass = self as! ObjectSchemaArrayProperty
            if let arrayItems = subclass.items as ObjectSchemaProperty? {
                assert(arrayItems.isScalarObjectiveCType() == false) // Arrays cannot contain primitive types
                if (arrayItems.jsonType == JSONType.Pointer ||
                   (arrayItems.jsonType == JSONType.String && (arrayItems as! ObjectSchemaStringProperty).format == JSONStringFormatType.Uri)) {
                    let deserializedObject = arrayItems.propertyStatementFromDictionary("obj")
                    return [
                        "NSArray *items = value;",
                        "NSMutableArray *result = [NSMutableArray arrayWithCapacity:items.count];",
                        "[items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {",
                        "    [result addObject:\(deserializedObject)];",
                        "}];",
                        "_\(formattedPropName) = result;"
                    ]

                }
            }
        case .Object:
            let subclass = self as! ObjectSchemaObjectProperty
            if let additionalProperties = subclass.additionalProperties as ObjectSchemaProperty? {
                assert(additionalProperties.isScalarObjectiveCType() == false) // Dictionaries cannot contain primitive types
                if additionalProperties.jsonType == JSONType.Pointer {
                    let deserializedObject = additionalProperties.propertyStatementFromDictionary("obj")
                    return [
                        "NSDictionary *items = value;",
                        "NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:items.count];",
                        "[items enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {",
                        "    result[key] = \(deserializedObject);",
                        "}];",
                        "_\(formattedPropName) = result;"
                    ]
                }
            }
        default:
            propertyAssignmentStatement = "_\(formattedPropName) = \(propFromDictionary);"
        }
        return [propertyAssignmentStatement]
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        var requiresAssignmentLogic = Bool(false)
        switch self.jsonType {
        case .Array :
            let subclass = self as! ObjectSchemaArrayProperty
            if let arrayItems = subclass.items as ObjectSchemaProperty? {
                assert(arrayItems.isScalarObjectiveCType() == false) // Arrays cannot contain primitive types
                if (arrayItems.jsonType == JSONType.Pointer ||
                    (arrayItems.jsonType == JSONType.String && (arrayItems as! ObjectSchemaStringProperty).format == JSONStringFormatType.Uri)) {
                        requiresAssignmentLogic = Bool(true)
                }
            }
        case .Object:
            let subclass = self as! ObjectSchemaObjectProperty
            if let additionalProperties = subclass.additionalProperties as ObjectSchemaProperty? {
                assert(additionalProperties.isScalarObjectiveCType() == false) // Dictionaries cannot contain primitive types
                if additionalProperties.jsonType == JSONType.Pointer {
                    requiresAssignmentLogic = Bool(true)
                }
            }
        case .Pointer:
            requiresAssignmentLogic = Bool(true)
        case .String :
            if self is ObjectSchemaStringProperty {
                let subclass = self as! ObjectSchemaStringProperty
                if subclass.format == JSONStringFormatType.Uri {
                    requiresAssignmentLogic = Bool(true)
                }
            }

        default:
            requiresAssignmentLogic = Bool(false)
        }

        return requiresAssignmentLogic
    }


    func isScalarObjectiveCType() -> Bool {
        return self.jsonType == JSONType.Boolean || self.jsonType == JSONType.Integer || self.jsonType == JSONType.Number
    }

    func objCMemoryAssignmentType() -> ObjCMemoryAssignmentType {
        if self.isScalarObjectiveCType() {
            return ObjCMemoryAssignmentType.Assign
        }

        switch self.jsonType {
        case .String:
            return ObjCMemoryAssignmentType.Copy
        default:
            return ObjCMemoryAssignmentType.Strong
        }
    }
}


class ObjectiveCProperty {
    let propertyDescriptor : ObjectSchemaProperty
    let atomicityType = ObjCAtomicityType.NonAtomic

    init(descriptor: ObjectSchemaProperty) {
        self.propertyDescriptor = descriptor
    }


    func renderInterfaceDeclaration() -> String {
        return self.renderDeclaration(false)
    }

    func renderImplementationDeclaration() -> String {
        return self.renderDeclaration(true)
    }

    private func renderDeclaration(isMutable: Bool) -> String {
        let mutabilityType = isMutable ? ObjCMutabilityType.ReadWrite : ObjCMutabilityType.ReadOnly
        let propName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let format : String = self.propertyDescriptor.isScalarObjectiveCType() ?  "%@ (%@) %@ %@;" : "%@ (%@) %@ *%@;"
        return String(format: format, "@property",
            ", ".join([
                self.atomicityType.rawValue,
                self.propertyDescriptor.objCMemoryAssignmentType().rawValue,
                mutabilityType.rawValue]),
            self.propertyDescriptor.objectiveCStringForJSONType(),
            propName)
    }
}