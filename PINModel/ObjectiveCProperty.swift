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


public enum ObjCPrimitiveType: String {
    case Float = "float"
    case Double = "double"
    case Integer = "NSInteger"
    case Boolean = "BOOL"
}


protocol ObjectiveCProperty: class {
    associatedtype SchemaType : ObjectSchemaProperty

    var propertyDescriptor: SchemaType { get set }
    var className: String { get set }
    var schemaLoader: SchemaLoader { get set }
    
    init(descriptor: SchemaType, className: String, schemaLoader: SchemaLoader)

    func renderInterfaceDeclaration() -> String
    func renderImplementationDeclaration() -> String
    func isScalarType() -> Bool
    func memoryAssignmentType() -> ObjCMemoryAssignmentType // Might not be necessary.
    func isEnumPropertyType() -> Bool // Potentially refactor enum methods out to another protocol or subprotocol
    func enumPropertyTypeName() -> String
    func renderEnumUtilityMethodsInterface() -> String
    func renderEnumDeclaration() -> String
    func renderEncodeWithCoderStatement() -> String
    func renderEncodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName: String) -> String
    func renderDecodeWithCoderStatement() -> String
    func renderDecodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName: String) -> String
    func renderDeclaration(isMutable: Bool) -> String
    func propertyRequiresAssignmentLogic() -> Bool
    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String
    func propertyAssignmentStatementFromDictionary(className: String) -> [String]
    func objectiveCStringForJSONType() -> String
    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String]
    func polymorphicTypeIdentifier() -> String
    func dirtyPropertyAssignmentStatement(dirtyPropertiesIVarName: String) -> String
}

class PropertyFactory {
    class func propertyForDescriptor(descriptor: ObjectSchemaProperty, className: String, schemaLoader: SchemaLoader) -> AnyProperty {
        switch descriptor {
        case let d as ObjectSchemaObjectProperty:
            return AnyProperty(ObjectiveCDictionaryProperty(descriptor: d, className: className, schemaLoader: schemaLoader))
        case let d as ObjectSchemaArrayProperty:
            return AnyProperty(ObjectiveCArrayProperty(descriptor: d, className: className, schemaLoader: schemaLoader))

        case let d as ObjectSchemaStringProperty:
            return AnyProperty(ObjectiveCStringProperty(descriptor: d, className: className, schemaLoader: schemaLoader))

        case let d as ObjectSchemaNumberProperty:
            return AnyProperty(ObjectiveCIntegerProperty(descriptor: d, className: className, schemaLoader: schemaLoader))

        case let d as ObjectSchemaBooleanProperty:
            return AnyProperty(ObjectiveCBooleanProperty(descriptor: d, className: className, schemaLoader: schemaLoader))
        case let d as ObjectSchemaPointerProperty:
            return AnyProperty(ObjectiveCClassProperty(descriptor: d, className: className, schemaLoader: schemaLoader))
        case let d as ObjectSchemaPolymorphicProperty:
            return AnyProperty(ObjectiveCPolymorphicProperty(descriptor: d, className: className, schemaLoader: schemaLoader))
        default:
            assert(false, "Unsupported Property Type")
            return AnyProperty(ObjectiveCDictionaryProperty(descriptor: descriptor as! ObjectSchemaObjectProperty, className: className, schemaLoader: schemaLoader))
        }
    }
}

class AnyProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaProperty
    var className: String
    var schemaLoader: SchemaLoader

    private var _renderInterfaceDeclaration: Void -> String
    private var _renderImplementationDeclaration: Void -> String
    private var _isScalarType: Void -> Bool
    private var _memoryAssignmentType: Void -> ObjCMemoryAssignmentType
    private var _isEnumPropertyType: Void -> Bool
    private var _enumPropertyTypeName: Void -> String
    private var _renderEnumUtilityMethodsInterface: Void -> String
    private var _renderEnumDeclaration: Void -> String
    private var _renderEncodeWithCoderStatement: Void -> String
    private var _renderEncodeWithCoderStatementForDirtyProperties: String -> String
    private var _renderDecodeWithCoderStatement: Void -> String
    private var _renderDecodeWithCoderStatementForDirtyProperties: String -> String
    private var _renderDeclaration: Bool -> String
    private var _propertyRequiresAssignmentLogic: Void -> Bool
    private var _propertyStatementFromDictionary: (String, String) -> String
    private var _propertyAssignmentStatementFromDictionary: String -> [String]
    private var _objectiveCStringForJSONType: Void -> String
    private var _propertyMergeStatementFromDictionary: (String, String) -> [String]
    private var _polymorphicTypeIdentifier: Void -> String
    private var _dirtyPropertyOption: Void -> String
    private var _dirtyPropertyAssignmentStatement: String -> String


    required init(descriptor: ObjectSchemaProperty, className: String, schemaLoader: SchemaLoader) {
        let base = PropertyFactory.propertyForDescriptor(descriptor, className: className, schemaLoader: schemaLoader)
        _renderInterfaceDeclaration = { base.renderInterfaceDeclaration() }
        _renderImplementationDeclaration = { base.renderImplementationDeclaration() }
        _isScalarType = { base.isScalarType() }
        _memoryAssignmentType = { base.memoryAssignmentType() }
        _isEnumPropertyType = { base.isEnumPropertyType() }
        _enumPropertyTypeName = { base.enumPropertyTypeName() }
        _renderEnumUtilityMethodsInterface = { base.renderEnumUtilityMethodsInterface() }
        _renderEnumDeclaration = { base.renderEnumDeclaration() }
        _renderEncodeWithCoderStatement = { base.renderEncodeWithCoderStatement() }
        _renderEncodeWithCoderStatementForDirtyProperties = { base.renderEncodeWithCoderStatementForDirtyProperties($0) }
        _renderDecodeWithCoderStatement = { base.renderDecodeWithCoderStatement() }
        _renderDecodeWithCoderStatementForDirtyProperties = { base.renderDecodeWithCoderStatementForDirtyProperties($0) }
        _propertyRequiresAssignmentLogic = { base.propertyRequiresAssignmentLogic() }
        _objectiveCStringForJSONType = { base.objectiveCStringForJSONType() }
        _propertyMergeStatementFromDictionary = { base.propertyMergeStatementFromDictionary($0, className: $1) }
        _propertyAssignmentStatementFromDictionary = { base.propertyAssignmentStatementFromDictionary($0) }
        _renderDeclaration = { base.renderDeclaration($0) }
        _propertyStatementFromDictionary = { base.propertyStatementFromDictionary($0, className: $1) }
        _polymorphicTypeIdentifier = { base.polymorphicTypeIdentifier() }
        _dirtyPropertyOption = { base.dirtyPropertyOption() }
        _dirtyPropertyAssignmentStatement = { base.dirtyPropertyAssignmentStatement($0) }

        self.propertyDescriptor = descriptor
        self.className = className
        self.schemaLoader = schemaLoader
    }


    init<A: ObjectiveCProperty>(_ base: A) {
        _renderInterfaceDeclaration = { base.renderInterfaceDeclaration() }
        _renderImplementationDeclaration = { base.renderImplementationDeclaration() }
        _isScalarType = { base.isScalarType() }
        _memoryAssignmentType = { base.memoryAssignmentType() }
        _isEnumPropertyType = { base.isEnumPropertyType() }
        _enumPropertyTypeName = { base.enumPropertyTypeName() }
        _renderEnumUtilityMethodsInterface = { base.renderEnumUtilityMethodsInterface() }
        _renderEnumDeclaration = { base.renderEnumDeclaration() }
        _renderEncodeWithCoderStatement = { base.renderEncodeWithCoderStatement() }
        _renderEncodeWithCoderStatementForDirtyProperties = { base.renderEncodeWithCoderStatementForDirtyProperties($0) }
        _renderDecodeWithCoderStatement = { base.renderDecodeWithCoderStatement() }
        _renderDecodeWithCoderStatementForDirtyProperties = { base.renderDecodeWithCoderStatementForDirtyProperties($0) }
        _propertyRequiresAssignmentLogic = { base.propertyRequiresAssignmentLogic() }
        _objectiveCStringForJSONType = { base.objectiveCStringForJSONType() }
        _propertyMergeStatementFromDictionary = { base.propertyMergeStatementFromDictionary($0, className: $1) }
        _propertyAssignmentStatementFromDictionary = { base.propertyAssignmentStatementFromDictionary($0) }
        _renderDeclaration = { base.renderDeclaration($0) }
        _propertyStatementFromDictionary = { base.propertyStatementFromDictionary($0, className: $1) }
        _polymorphicTypeIdentifier = { base.polymorphicTypeIdentifier() }
        _dirtyPropertyOption = { base.dirtyPropertyOption() }
        _dirtyPropertyAssignmentStatement = { base.dirtyPropertyAssignmentStatement($0) }

        self.propertyDescriptor = base.propertyDescriptor
        self.className = base.className
        self.schemaLoader = base.schemaLoader
    }

    func renderInterfaceDeclaration() -> String {
        return _renderInterfaceDeclaration()
    }

    func renderImplementationDeclaration() -> String {
        return _renderImplementationDeclaration()
    }

    func polymorphicTypeIdentifier() -> String {
        return _polymorphicTypeIdentifier()
    }

    func isScalarType() -> Bool {
        return _isScalarType()
    }

    func memoryAssignmentType() -> ObjCMemoryAssignmentType {
        return _memoryAssignmentType()
    }

    func isEnumPropertyType() -> Bool {
        return _isEnumPropertyType()
    }

    func enumPropertyTypeName() -> String {
        return _enumPropertyTypeName()
    }

    func renderEnumUtilityMethodsInterface() -> String {
        return _renderEnumUtilityMethodsInterface()
    }

    func renderEnumDeclaration() -> String {
        return _renderEnumDeclaration()
    }

    func renderEncodeWithCoderStatement() -> String {
        return _renderEncodeWithCoderStatement()
    }
    
    func renderEncodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName: String) -> String {
        return _renderEncodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName)
    }

    func renderDecodeWithCoderStatement() -> String {
        return _renderDecodeWithCoderStatement()
    }

    func renderDecodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName: String) -> String {
        return _renderDecodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName)
    }
    
    func renderDeclaration(isMutable: Bool) -> String {
        return _renderDeclaration(isMutable)
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return _propertyRequiresAssignmentLogic()
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        return _propertyStatementFromDictionary(propertyVariableString, className)
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {
        return _propertyAssignmentStatementFromDictionary(className)
    }

    func objectiveCStringForJSONType() -> String {
        return _objectiveCStringForJSONType()
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        return _propertyMergeStatementFromDictionary(originVariableString, className)
    }

    func dirtyPropertyAssignmentStatement(dirtyPropertiesIVarName: String) -> String {
        return _dirtyPropertyAssignmentStatement(dirtyPropertiesIVarName)
    }
}

extension ObjectiveCProperty {
    
    func renderInterfaceDeclaration() -> String {
        return self.renderDeclaration(false)
    }

    func renderImplementationDeclaration() -> String {
        return self.renderDeclaration(true)
    }

    func polymorphicTypeIdentifier() -> String {
        return self.propertyDescriptor.algebraicDataTypeIdentifier
    }

    func isScalarType() -> Bool {
        let jsonType = self.propertyDescriptor.jsonType
        return jsonType == JSONType.Boolean || jsonType == JSONType.Integer || jsonType == JSONType.Number || (jsonType == JSONType.String && self.isEnumPropertyType())
    }

    internal func memoryAssignmentType() -> ObjCMemoryAssignmentType {
        if self.isScalarType() {
            return ObjCMemoryAssignmentType.Assign
        }

        // Since we are generating immutable models we can avoid declaring properties with "copy" memory assignment types.
        return ObjCMemoryAssignmentType.Strong
    }

    func isEnumPropertyType() -> Bool {
        return self.propertyDescriptor.enumValues.count > 0
    }

    func enumPropertyTypeName() -> String {
        return className + (rawEnumPrefix + "_type").snakeCaseToCamelCase()
    }
    
    func renderEnumUtilityMethodsInterface() -> String {
        return ["extern \(self.enumPropertyTypeName()) \(self.enumPropertyTypeName())FromString(NSString * _Nonnull str);",
            "extern NSString * _Nonnull \(self.enumPropertyTypeName())ToString(\(self.enumPropertyTypeName()) enumType);"].joinWithSeparator("\n")

    }

    func renderEnumDeclaration() -> String {
        assert(false, "We don't handle enums that are not strings or integer values")
        return "";
    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }
    
    func renderEncodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName: String) -> String {
        return "[aCoder encodeInt:_\(dirtyPropertiesIVarName).\(self.dirtyPropertyOption()) forKey:@\"\(self.propertyDescriptor.name)_dirty_property\"];"
    }

    func renderDecodeWithCoderStatement() -> String {
        assert(false)
        return ""
    }
    
    func renderDecodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName: String) -> String {
        return "_\(dirtyPropertiesIVarName).\(self.dirtyPropertyOption()) = [aDecoder decodeIntForKey:@\"\(self.propertyDescriptor.name)_dirty_property\"];"
    }

    internal func renderDeclaration(isMutable: Bool) -> String {
        let mutabilityType = isMutable ? ObjCMutabilityType.ReadWrite: ObjCMutabilityType.ReadOnly
        let propName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let format: String = self.isScalarType() ?  "%@ (%@) %@ %@;": "%@ (%@) %@ *%@;"
        if self.isScalarType() {
            return String(format: format, "@property",
                [ObjCAtomicityType.NonAtomic.rawValue,
                    self.memoryAssignmentType().rawValue,
                    mutabilityType.rawValue].joinWithSeparator(", "),
                self.objectiveCStringForJSONType(),
                propName)
        } else {
            return String(format: format, "@property",
                ["nullable", // We don't have a notion of required fields so we must assume all are nullable
                    ObjCAtomicityType.NonAtomic.rawValue,
                    self.memoryAssignmentType().rawValue,
                    mutabilityType.rawValue].joinWithSeparator(", "),
                self.objectiveCStringForJSONType(),
                propName)
        }
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return false
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
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
        return [propertyAssignmentStatement]
    }

    func dirtyPropertyOption() -> String {
        let propertyName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let capitalizedFirstLetter = String(propertyName[propertyName.startIndex]).uppercaseString
        let capitalizedPropertyName = capitalizedFirstLetter + String(propertyName.characters.dropFirst())
        return self.className + "DirtyProperty" + capitalizedPropertyName
    }

    func dirtyPropertyAssignmentStatement(dirtyPropertiesIVarName : String) -> String {
        let dirtyPropertyOption = self.dirtyPropertyOption()
        return "_\(dirtyPropertiesIVarName).\(dirtyPropertyOption) = 1;"
    }
    
    private var rawEnumPrefix: String {
        var nameParts = propertyDescriptor.name.componentsSeparatedByString("_")
        if nameParts.last?.lowercaseString == "type" {
            nameParts.removeLast()
        }
        return nameParts.joinWithSeparator("_")
    }
}
