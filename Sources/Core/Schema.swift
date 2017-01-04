//
//  schema.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

typealias JSONObject = [String:Any]

public enum JSONType: String {
    case Object = "object"
    case Array = "array"
    case String = "string"
    case Integer = "integer"
    case Number = "number"
    case Boolean = "boolean"
//    case Null = "null"
    case Pointer = "$ref" // Used for combining schemas via references.
    case Polymorphic = "oneOf" // JSONType composed of other JSONTypes

    static func typeFromProperty(prop: JSONObject) -> JSONType? {
        if let _ = prop["oneOf"] as? [JSONObject] {
            return JSONType.Polymorphic
        }

        if let _ = prop["$ref"] as? String {
            return JSONType.Pointer
        }

        return (prop["type"] as? String).flatMap(JSONType.init)
    }
}

public enum StringFormatType: String {
    case DateTime = "date-time"  // Date representation, as defined by RFC 3339, section 5.6.
    case Email = "email"  // Internet email address, see RFC 5322, section 3.4.1.
    case Hostname = "hostname"  // Internet host name, see RFC 1034, section 3.1.
    case Ipv4 = "ipv4"  // IPv4 address, according to dotted-quad ABNF syntax as defined in RFC 2673, section 3.2.
    case Ipv6 = "ipv6"  // IPv6 address, as defined in RFC 2373, section 2.2.
    case Uri = "uri"  // A universal resource identifier (URI), according to RFC3986.
}

struct EnumValue<ValueType> {
    let defaultValue: ValueType
    let description: String

    init(object: JSONObject) throws {
        if let defaultVal = object["default"] as? ValueType, let descriptionVal = object["description"] as? String {
            defaultValue = defaultVal
            description = descriptionVal
        } else {
            throw JSONParseError()
        }
    }
}

indirect enum EnumType {
    case Integer([EnumValue<Int>]) // TODO: Revisit if we should have default values for integer enums
    case String([EnumValue<String>], defaultValue: EnumValue<String>)
}

typealias LazySchemaReference = () -> Schema?

typealias Property = (Parameter, Schema)

struct JSONParseError: Error {}

extension Dictionary {
    init(elements:[(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

func decodeRef(from source: URL, with ref: String) -> URL {
    if ref.hasPrefix("#") {
        // Local URL
        return URL(string:ref, relativeTo:source)!
    } else {
        var baseUrl = source.deletingLastPathComponent()
        if baseUrl.path == "." {
            baseUrl = URL(fileURLWithPath: (baseUrl.path))
        }
        let lastPathComponentString = URL(string: ref)?.pathComponents.last
        return URL(string:lastPathComponentString!, relativeTo:baseUrl)!
    }
}

struct SchemaObjectRoot: Equatable {
    let name: String
    let properties: [String:Schema]
    let extends: LazySchemaReference?
    let algebraicTypeIdentifier: String?

    var typeIdentifier: String {
        get {
            return algebraicTypeIdentifier ?? name
        }
    }
}

func ==(lhs: SchemaObjectRoot, rhs: SchemaObjectRoot) -> Bool {
    return lhs.name == rhs.name
}


let RootNSObject = SchemaObjectRoot(name: "NSObject", properties: [:], extends: nil, algebraicTypeIdentifier: nil)

extension SchemaObjectRoot : CustomDebugStringConvertible {
    public var debugDescription: String {
        return (["\(name)\n extends from \(extends.map{ $0()?.debugDescription })\n"] + properties.map { (k, v) in "\t\(k): \(v.debugDescription)\n" }).reduce("", +)
    }
}

indirect enum Schema {
    case Object(SchemaObjectRoot)
    case Array(itemType: Schema?)
    case Map(valueType: Schema?) // TODO: Should we have an option to specify the key type? (probably yes)
    case Integer
    case Float
    case Boolean
    case String(format: StringFormatType?)
    case OneOf(types: [Schema]) // ADT
    case Enum(EnumType)
    case Reference(with: LazySchemaReference)
}


extension Schema : CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .Array(itemType: let itemType):
            return "Array: \(itemType.debugDescription)"
        case .Object(let root):
            return "Object: \(root.debugDescription)"
        case .Map(valueType: let valueType):
            return "Map: \(valueType?.debugDescription)"
        case .Integer:
            return "Integer"
        case .Float:
            return "Float"
        case .Boolean:
            return "Boolean"
        case .String:
            return "String"
        case .OneOf(types: let types):
            return (["OneOf"] + types.map { v in "\t\(v.debugDescription)\n" }).reduce("", +)
        case .Enum(let enumType):
            return "Enum: \(enumType)"
        case .Reference(with: _):
            return "Reference"
        }
    }
}


extension Schema {
    // Computed Properties
    var title: String? {
        switch self {
        case .Object(let rootObject):
            return rootObject.name
        default:
            return nil
        }
    }

    func extends() -> Schema? {
        switch self {
        case .Object(let rootObject):
            return rootObject.extends.flatMap { $0() }
        default:
            return nil
        }
    }
}

extension Schema {
    static func propertyFunctionForType(loader: SchemaLoader) -> (JSONObject, URL) -> Schema? {
        func propertyForType(propertyInfo: JSONObject, source: URL) -> Schema? {
            let title = propertyInfo["title"] as? String
            // Check for "type"
            guard let propType = JSONType.typeFromProperty(prop: propertyInfo) else { return nil }

            switch propType {
            case JSONType.String:
                if let enumValues = propertyInfo["enum"] as? [JSONObject], let defaultValue = propertyInfo["default"] as? String {
                    let enumVals = try? enumValues.map(EnumValue<String>.init)
                    let defaultVal = enumVals?.first(where: { $0.defaultValue == defaultValue })
                    return enumVals
                        .flatMap{ v in defaultVal.map{ ($0, v) } }
                        .map{ defaultVal, enumVals in
                            Schema.Enum(EnumType.String(enumVals, defaultValue: defaultVal))
                        }
                } else {
                    return Schema.String(format: (propertyInfo["format"] as? String).flatMap(StringFormatType.init))
                }
            case JSONType.Array:
                return .Array(itemType: (propertyInfo["items"] as? JSONObject)
                        .flatMap { propertyForType(propertyInfo: $0, source: source)})
            case JSONType.Integer:
                if let enumValues = propertyInfo["enum"] as? [JSONObject] {
                    return try? Schema.Enum(EnumType.Integer(enumValues.map(EnumValue<Int>.init)))
                } else {
                    return .Integer
                }
            case JSONType.Number:
                return .Float
            case JSONType.Boolean:
                return .Boolean
            case JSONType.Pointer:
                return (propertyInfo["$ref"] as? String).map { ref in
                    .Reference(with: { () -> Schema? in
                        loader.loadSchema(decodeRef(from: source, with: ref))
                    })
                }
            case JSONType.Object:
                if let propMap = propertyInfo["properties"] as? JSONObject, let objectTitle = title {
                    // Class
                    let optTuples: [Property?] = propMap.map { (k, v) -> (String, Schema?) in
                        let schemaOpt = (v as? JSONObject).flatMap {
                                propertyForType(propertyInfo: $0, source: source)
                        }
                        return (k, schemaOpt)
                        }.map { (name, optSchema) in optSchema.map{ (name, $0) } }
                    let lifted: [Property]? = optTuples.reduce([], { (build: [Property]?, tupleOption: Property?) -> [Property]? in
                        build.flatMap { (b: [Property]) -> [Property]? in tupleOption.map{ b + [$0] } }
                    })
                    let extends = (propertyInfo["extends"] as? JSONObject)
                        .flatMap { ($0["$ref"] as? String).map { ref in {
                            loader.loadSchema(decodeRef(from: source, with: ref)) } } }

                    return lifted.map { Schema.Object(SchemaObjectRoot(name: objectTitle,
                                                                       properties: Dictionary(elements: $0),
                                                                       extends: extends,
                                                                       algebraicTypeIdentifier: propertyInfo["algebraicDataTypeIdentifier"] as? String)) }
                } else {
                    // Map type
                    return Schema.Map(valueType:(propertyInfo["additionalProperties"] as? JSONObject)
                        .flatMap { propertyForType(propertyInfo: $0, source: source) })
                }
            case JSONType.Polymorphic:
                return (propertyInfo["oneOf"] as? [JSONObject]) // [JSONObject]
                    .map { jsonObjs in jsonObjs.map { propertyForType(propertyInfo: $0, source: source) } } // [Schema?]?
                    .flatMap { schemas in schemas.reduce([], { (build: [Schema]?, tupleOption: Schema?) -> [Schema]? in
                        build.flatMap { (b: [Schema]) -> [Schema]? in tupleOption.map{ b + [$0] } }
                    }) }
                    .map{ Schema.OneOf(types: $0) }
            }

        }
        return propertyForType
    }
}
