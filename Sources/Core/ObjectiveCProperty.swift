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
    func renderEncodeWithCoderStatementForDirtyProperties(_ dirtyPropertiesIVarName: String) -> String
    func renderDecodeWithCoderStatement() -> String
    func renderDecodeWithCoderStatementForDirtyProperties(_ dirtyPropertiesIVarName: String) -> String
    func renderDeclaration(_ isMutable: Bool) -> String
    func propertyRequiresAssignmentLogic() -> Bool
    func propertyStatementFromDictionary(_ propertyVariableString: String, className: String) -> String
    func propertyAssignmentStatementFromDictionary(_ className: String) -> [String]
    func objectiveCStringForJSONType() -> String
    func polymorphicTypeIdentifier() -> String
    func dirtyPropertyAssignmentStatement(_ dirtyPropertiesIVarName: String) -> String
}

class PropertyFactory {
    class func propertyForDescriptor(_ descriptor: ObjectSchemaProperty, className: String, schemaLoader: SchemaLoader) -> AnyProperty {
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

    fileprivate var _renderInterfaceDeclaration: (Void) -> String
    fileprivate var _renderImplementationDeclaration: (Void) -> String
    fileprivate var _isScalarType: (Void) -> Bool
    fileprivate var _memoryAssignmentType: (Void) -> ObjCMemoryAssignmentType
    fileprivate var _isEnumPropertyType: (Void) -> Bool
    fileprivate var _enumPropertyTypeName: (Void) -> String
    fileprivate var _renderEnumUtilityMethodsInterface: (Void) -> String
    fileprivate var _renderEnumDeclaration: (Void) -> String
    fileprivate var _renderEncodeWithCoderStatement: (Void) -> String
    fileprivate var _renderEncodeWithCoderStatementForDirtyProperties: (String) -> String
    fileprivate var _renderDecodeWithCoderStatement: (Void) -> String
    fileprivate var _renderDecodeWithCoderStatementForDirtyProperties: (String) -> String
    fileprivate var _renderDeclaration: (Bool) -> String
    fileprivate var _propertyRequiresAssignmentLogic: (Void) -> Bool
    fileprivate var _propertyStatementFromDictionary: (String, String) -> String
    fileprivate var _propertyAssignmentStatementFromDictionary: (String) -> [String]
    fileprivate var _objectiveCStringForJSONType: (Void) -> String
    fileprivate var _polymorphicTypeIdentifier: (Void) -> String
    fileprivate var _dirtyPropertyOption: (Void) -> String
    fileprivate var _dirtyPropertyAssignmentStatement: (String) -> String

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
    
    func renderEncodeWithCoderStatementForDirtyProperties(_ dirtyPropertiesIVarName: String) -> String {
        return _renderEncodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName)
    }

    func renderDecodeWithCoderStatement() -> String {
        return _renderDecodeWithCoderStatement()
    }

    func renderDecodeWithCoderStatementForDirtyProperties(_ dirtyPropertiesIVarName: String) -> String {
        return _renderDecodeWithCoderStatementForDirtyProperties(dirtyPropertiesIVarName)
    }
    
    func renderDeclaration(_ isMutable: Bool) -> String {
        return _renderDeclaration(isMutable)
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return _propertyRequiresAssignmentLogic()
    }

    func propertyStatementFromDictionary(_ propertyVariableString: String, className: String) -> String {
        return _propertyStatementFromDictionary(propertyVariableString, className)
    }

    func propertyAssignmentStatementFromDictionary(_ className: String) -> [String] {
        return _propertyAssignmentStatementFromDictionary(className)
    }

    func objectiveCStringForJSONType() -> String {
        return _objectiveCStringForJSONType()
    }

    func dirtyPropertyAssignmentStatement(_ dirtyPropertiesIVarName: String) -> String {
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
        return ["extern \(self.enumPropertyTypeName()) \(self.renderEnumUtilityMethodEnumToString())(NSString * _Nonnull str);",
            "extern NSString * _Nonnull \(self.renderEnumUtilityMethodStringToEnum())(\(self.enumPropertyTypeName()) enumType);"].joined(separator: "\n")
    }

    func renderEnumUtilityMethodEnumToString() -> String {
        return "\(self.enumPropertyTypeName())ToString"
    }

    func renderEnumUtilityMethodStringToEnum() -> String {
        return "\(self.enumPropertyTypeName())FromString"

    }

    func renderEnumDeclaration() -> String {
        assert(false, "We don't handle enums that are not strings or integer values")
        return "";
    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeObject:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }
    
    func renderEncodeWithCoderStatementForDirtyProperties(_ dirtyPropertiesIVarName: String) -> String {
        return "[aCoder encodeInt:_\(dirtyPropertiesIVarName).\(self.dirtyPropertyOption()) forKey:@\"\(self.propertyDescriptor.name)_dirty_property\"];"
    }

    func renderDecodeWithCoderStatement() -> String {
        assert(false)
        return ""
    }
    
    func renderDecodeWithCoderStatementForDirtyProperties(_ dirtyPropertiesIVarName: String) -> String {
        return "_\(dirtyPropertiesIVarName).\(self.dirtyPropertyOption()) = [aDecoder decodeIntForKey:@\"\(self.propertyDescriptor.name)_dirty_property\"];"
    }

    internal func renderDeclaration(_ isMutable: Bool) -> String {
        let mutabilityType = isMutable ? ObjCMutabilityType.ReadWrite: ObjCMutabilityType.ReadOnly
        let propName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let typeName = self.objectiveCStringForJSONType()
        if self.isScalarType() {
            let propAttributes =  [ObjCAtomicityType.NonAtomic.rawValue, self.memoryAssignmentType().rawValue, mutabilityType.rawValue]
            return  "@property (\(propAttributes.joined(separator: ", "))) \(typeName) \(propName);"
        } else {
            let propAttributes =  ["nullable", ObjCAtomicityType.NonAtomic.rawValue, self.memoryAssignmentType().rawValue, mutabilityType.rawValue]
            return  "@property (\(propAttributes.joined(separator: ", "))) \(typeName) *\(propName);"
        }
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        return false
    }

    func propertyStatementFromDictionary(_ propertyVariableString: String, className: String) -> String {
        return propertyVariableString
    }

    func propertyAssignmentStatementFromDictionary(_ className: String) -> [String] {
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
        let capitalizedFirstLetter = String(propertyName[propertyName.startIndex]).uppercased()
        let capitalizedPropertyName = capitalizedFirstLetter + String(propertyName.characters.dropFirst())
        return self.className + "DirtyProperty" + capitalizedPropertyName
    }

    func dirtyPropertyAssignmentStatement(_ dirtyPropertiesIVarName: String) -> String {
        let dirtyPropertyOption = self.dirtyPropertyOption()
        return "_\(dirtyPropertiesIVarName).\(dirtyPropertyOption) = 1;"
    }
    
    fileprivate var rawEnumPrefix: String {
        var nameParts = propertyDescriptor.name.components(separatedBy: "_")
        if nameParts.last?.lowercased() == "type" {
            nameParts.removeLast()
        }
        return nameParts.joined(separator: "_")
    }
}
