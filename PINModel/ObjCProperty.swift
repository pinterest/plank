//
//  ObjCProperty.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

// MARK: Objective-C Helpers

let DateValueTransformerKey = "kPINModelDateValueTransformerKey"

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


public enum ObjCPrimitiveType: String {
    case Float = "CGFloat"
    case Integer = "NSInteger"
    case Boolean = "BOOL"
}


extension ObjectSchemaProperty {
    func objectiveCStringForJSONType(className : String = "") -> String {
        switch self.jsonType {
        case .String :
            if self is ObjectSchemaStringProperty {
                let subclass = self as! ObjectSchemaStringProperty
                if subclass.format == JSONStringFormatType.Uri {
                    return NSStringFromClass(NSURL)
                } else if subclass.format == JSONStringFormatType.DateTime {
                    return NSStringFromClass(NSDate)
                }
            }
            return NSStringFromClass(NSString)
        case .Number :
            return ObjCPrimitiveType.Float.rawValue
        case .Integer :
            let objCProp = ObjectiveCProperty(descriptor: self, className : className)
            if objCProp.isEnumPropertyType() {
                return objCProp.enumPropertyTypeName()
            }
            return ObjCPrimitiveType.Integer.rawValue
        case .Boolean:
            return ObjCPrimitiveType.Boolean.rawValue
        case .Array:
            if self is ObjectSchemaArrayProperty {
                let subclass = self as! ObjectSchemaArrayProperty
                if let valueTypes = subclass.items as ObjectSchemaProperty? {
                    return "\(NSStringFromClass(NSArray)) <\(valueTypes.objectiveCStringForJSONType()) *>"
                }
            }
            return NSStringFromClass(NSArray)
        case .Object:
            if self is ObjectSchemaObjectProperty {
                let subclass = self as! ObjectSchemaObjectProperty
                if let valueTypes = subclass.additionalProperties as ObjectSchemaProperty? {
                    return "\(NSStringFromClass(NSDictionary)) <\(NSStringFromClass(NSString)) *, \(valueTypes.objectiveCStringForJSONType()) *>"
                } else {
                    return "\(NSStringFromClass(NSDictionary)) <\(NSStringFromClass(NSString)) *, \(NSStringFromClass(NSObject)) *>"
                }
            }
            return NSStringFromClass(NSDictionary)
        case .Pointer:
            let subclass = self as! ObjectSchemaPointerProperty
            if let schema = SchemaLoader.sharedInstance.loadSchema(subclass.ref) as? ObjectSchemaObjectProperty {
                // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
                // https://phabricator.pinadmin.com/T46
                return ObjectiveCInterfaceFileDescriptor(descriptor: schema, generatorParameters: [GenerationParameterType.ClassPrefix : "PI"], parentDescriptor: nil).className
            } else {
                // TODO (rmalik): Add assertion back when we figure out why the API can have a null value for a schema.
                // https://phabricator.pinadmin.com/T47
//                assert(false)
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
                } else if subclass.format == JSONStringFormatType.DateTime {
                    statement = "[[NSValueTransformer valueTransformerForName:\(DateValueTransformerKey)] transformedValue:\(propertyVariableString)]"
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
                // TODO (rmalik): Add assertion back when we figure out why the API can have a null value for a schema.
                // https://phabricator.pinadmin.com/T47
                statement = ""
//                assert(false)
            }

        default:
            statement = propertyVariableString
        }
        return statement
    }



    func propertyMergeStatementFromDictionary(originVariableString : String) -> [String] {
        let formattedPropName = self.name.snakeCaseToPropertyName()
        let propFromDictionary = self.propertyStatementFromDictionary("value")

        if self.propertyRequiresAssignmentLogic() == false {
            // Code optimization: Early-exit if we are simply doing a basic assignment
            let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.name)\")")
            return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
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
                            "for (id obj in items) {",
                            "    [result addObject:\(deserializedObject)];",
                            "}",
                            "\(originVariableString).\(formattedPropName) = result;"
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
                        "[items enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, __unused BOOL *stop) {",
                        "    result[key] = \(deserializedObject);",
                        "}];",
                        "\(originVariableString).\(formattedPropName) = result;"
                    ]
                }
            }
        case .Pointer:
            let subclass = self as! ObjectSchemaPointerProperty
            let propStmt = subclass.propertyStatementFromDictionary("value")
            return [
                "if (\(originVariableString).\(formattedPropName) != nil) {",
                "   \(originVariableString).\(formattedPropName) = [\(originVariableString).\(formattedPropName) mergeWithDictionary:value];",
                "} else {",
                "   \(originVariableString).\(formattedPropName) = \(propStmt);",
                "}"
            ]
        default:
            propertyAssignmentStatement = "\(originVariableString).\(formattedPropName) = \(propFromDictionary);"
        }
        return [propertyAssignmentStatement]
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
                        "for (id obj in items) {",
                        "    [result addObject:\(deserializedObject)];",
                        "}",
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
                return arrayItems.propertyRequiresAssignmentLogic()
            }
        case .Object:
            let subclass = self as! ObjectSchemaObjectProperty
            if let additionalProperties = subclass.additionalProperties as ObjectSchemaProperty? {
                assert(additionalProperties.isScalarObjectiveCType() == false) // Dictionaries cannot contain primitive types
                return additionalProperties.propertyRequiresAssignmentLogic()
            }
        case .Pointer:
            requiresAssignmentLogic = Bool(true)
        case .String :
            if self is ObjectSchemaStringProperty {
                let subclass = self as! ObjectSchemaStringProperty
                if subclass.format == JSONStringFormatType.Uri || subclass.format == JSONStringFormatType.DateTime {
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

        // Since we are generating immutable models we can avoid declaring properties with "copy" memory assignment types.
        return ObjCMemoryAssignmentType.Strong
    }
}


class ObjectiveCProperty {
    let propertyDescriptor : ObjectSchemaProperty
    let atomicityType = ObjCAtomicityType.NonAtomic
    let className : String

    init(descriptor: ObjectSchemaProperty, className : String = "") {
        self.propertyDescriptor = descriptor
        self.className = className
    }


    func renderInterfaceDeclaration() -> String {
        return self.renderDeclaration(false)
    }

    func renderImplementationDeclaration() -> String {
        return self.renderDeclaration(true)
    }

    func isEnumPropertyType() -> Bool {
        return self.propertyDescriptor.enumValues.count > 0
    }

    func enumPropertyTypeName() -> String {
        // TODO: Expose class prefix in a better way.
        return self.className + (self.propertyDescriptor.name + "_type").snakeCaseToCamelCase()
    }

    func renderEnumDeclaration() -> String {
        assert(self.isEnumPropertyType())

        let indent = "    "
        if self.propertyDescriptor.jsonType == JSONType.Integer {
            let enumTypeValues = self.propertyDescriptor.enumValues.map({ (val : [String : AnyObject]) -> String in
                let description = val["description"] as! String
                let defaultVal = val["default"] as! Int
                let enumValueName = self.enumPropertyTypeName() + description.snakeCaseToCamelCase()
                return indent + "\(enumValueName) = \(defaultVal)"
            })
            return ["typedef NS_ENUM(NSInteger, \(self.enumPropertyTypeName())) {",
                    enumTypeValues.joinWithSeparator(",\n"),
                    "};"].joinWithSeparator("\n")
        } else if self.propertyDescriptor.jsonType == JSONType.String {

        }
        assert(false, "We don't handle enums that are not strings or integer values")
        return "";

    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        switch self.propertyDescriptor.jsonType {
        case .Pointer:
            return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
        case .Integer:
            //- (void)encodeInt:(int)intv forKey:(NSString *)key;
            return "[aCoder encodeInteger:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
        case .Boolean:
            //- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key;
            return "[aCoder encodeBool:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"

        case .Number:
            //- (void)encodeFloat:(float)realv forKey:(NSString *)key;

            return "[aCoder encodeCGFloat:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
        default:
            return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
        }
    }

    func renderDecodeWithCoderStatement() -> String {
        switch self.propertyDescriptor.jsonType {
        case .Pointer:
            //- (id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
            let subclass = self.propertyDescriptor as! ObjectSchemaPointerProperty
            if let schema = SchemaLoader.sharedInstance.loadSchema(subclass.ref) as? ObjectSchemaObjectProperty {
                // TODO: Figure out how to expose generation parameters here or alternate ways to create the class name
                // https://phabricator.pinadmin.com/T46
                let className = ObjectiveCInterfaceFileDescriptor(descriptor: schema, generatorParameters: [GenerationParameterType.ClassPrefix : "PI"], parentDescriptor: nil).className
                return "[aDecoder decodeObjectOfClass:[\(className) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
            } else {
                // Failed to load schema
                assert(false)
            }
        case .Integer:
            // - (int)decodeIntForKey:(NSString *)key;
            return "[aDecoder decodeIntegerForKey:@\"\(self.propertyDescriptor.name)\"]"
        case .Boolean:
            // - (BOOL)decodeBoolForKey:(NSString *)key;
            return "[aDecoder decodeBoolForKey:@\"\(self.propertyDescriptor.name)\"]"
        case .Number:
            // - (float)decodeFloatForKey:(NSString *)key;
            return "[aDecoder decodeCGFloatForKey:@\"\(self.propertyDescriptor.name)\"]"
        case .String:
            return "[aDecoder decodeObjectOfClass:[\(self.propertyDescriptor.objectiveCStringForJSONType()) class] forKey:@\"\(self.propertyDescriptor.name)\"]"
        case .Array:
            // - (id)decodeObjectOfClasses:(NSSet *)classes forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
            var deserializationClasses = Set(["NSArray"])
            let subclass = self.propertyDescriptor as! ObjectSchemaArrayProperty
            if let valueTypes = subclass.items as ObjectSchemaProperty? {
                deserializationClasses.insert(valueTypes.objectiveCStringForJSONType())
            }
            let classList = deserializationClasses.map { "[\($0) class]" }.joinWithSeparator(", ")
            return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
        case .Object:
            // - (id)decodeObjectOfClasses:(NSSet *)classes forKey:(NSString *)key NS_AVAILABLE(10_8, 6_0);
            var deserializationClasses = Set(["NSDictionary", "NSString"])
            let subclass = self.propertyDescriptor as! ObjectSchemaObjectProperty
            if let valueTypes = subclass.additionalProperties as ObjectSchemaProperty? {
                deserializationClasses.insert(valueTypes.objectiveCStringForJSONType())
            }
            let classList = deserializationClasses.map { "[\($0) class]" }.joinWithSeparator(", ")
            return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
        default:
            assert(false)
        }
        return ""
    }

    private func isScalarType() -> Bool {
        let jsonType = self.propertyDescriptor.jsonType
        return jsonType == JSONType.Boolean || jsonType == JSONType.Integer || jsonType == JSONType.Number
    }

    private func renderDeclaration(isMutable: Bool) -> String {
        let mutabilityType = isMutable ? ObjCMutabilityType.ReadWrite : ObjCMutabilityType.ReadOnly
        let propName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let format : String = self.propertyDescriptor.isScalarObjectiveCType() ?  "%@ (%@) %@ %@;" : "%@ (%@) %@ *%@;"
        if self.isScalarType() {
            return String(format: format, "@property",
                [self.atomicityType.rawValue,
                 self.propertyDescriptor.objCMemoryAssignmentType().rawValue,
                 mutabilityType.rawValue].joinWithSeparator(", "),
                 self.propertyDescriptor.objectiveCStringForJSONType(self.className),
                 propName)
        } else {
            return String(format: format, "@property",
                ["nullable", // We don't have a notion of required fields so we must assume all are nullable
                    self.atomicityType.rawValue,
                    self.propertyDescriptor.objCMemoryAssignmentType().rawValue,
                    mutabilityType.rawValue].joinWithSeparator(", "),
                self.propertyDescriptor.objectiveCStringForJSONType(self.className),
                propName)
        }
    }
}