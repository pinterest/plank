//
//  schema.swift
//  Plank
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

typealias JSONObject = [String: Any]

public enum JSONType: String {
    case object = "object"
    case array = "array"
    case string = "string"
    case integer = "integer"
    case number = "number"
    case boolean = "boolean"
    case pointer = "$ref" // Used for combining schemas via references.
    case polymorphic = "oneOf" // JSONType composed of other JSONTypes

    static func typeFromProperty(prop: JSONObject) -> JSONType? {
        if (prop["oneOf"] as? [JSONObject]) != nil {
            return JSONType.polymorphic
        }

        if (prop["$ref"] as? String) != nil {
            return JSONType.pointer
        }

        return (prop["type"] as? String).flatMap(JSONType.init)
    }
}

public enum StringFormatType: String {
    case dateTime = "date-time"  // Date representation, as defined by RFC 3339, section 5.6.
    case email = "email"  // Internet email address, see RFC 5322, section 3.4.1.
    case hostname = "hostname"  // Internet host name, see RFC 1034, section 3.1.
    case ipv4 = "ipv4"  // IPv4 address, according to dotted-quad ABNF syntax as defined in RFC 2673, section 3.2.
    case ipv6 = "ipv6"  // IPv6 address, as defined in RFC 2373, section 2.2.
    case uri = "uri"  // A universal resource identifier (URI), according to RFC3986.
}

public struct EnumValue<ValueType> {
    let defaultValue: ValueType
    let description: String

    init(defaultValue: ValueType, description: String) {
        self.defaultValue = defaultValue
        self.description = description
    }

    init(withObject object: JSONObject) {
        if let defaultVal = object["default"] as? ValueType, let descriptionVal = object["description"] as? String {
            defaultValue = defaultVal
            description = descriptionVal
        } else {
           fatalError("Invalid schema specification for enum: \(object)")
        }
    }
}

public indirect enum EnumType {
    case integer([EnumValue<Int>]) // TODO: Revisit if we should have default values for integer enums
    case string([EnumValue<String>], defaultValue: EnumValue<String>)
}

public struct URLSchemaReference: LazySchemaReference {
    let url: URL
    public let force: () -> Schema?
}
public protocol LazySchemaReference {
    var force: () -> Schema? { get }
}

extension Dictionary {
    init(elements: [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

func decodeRef(from source: URL, with ref: String) -> URL {
    if ref.hasPrefix("#") {
        // Local URL
        return URL(string: ref, relativeTo: source)!
    } else {
        let baseUrl = source.deletingLastPathComponent()
        let lastPathComponentString = URL(string: ref)?.pathComponents.last
        return baseUrl.appendingPathComponent(lastPathComponentString!)
    }
}

public enum Nullability: String {
    case nullable
    case nonnull
}

// Ask @bkase about whether this makes more sense to wrap schemas to express nullability
// or if it would be better to have a protocol (i.e. NullabilityProperty) that we would pattern
// match on to detect nullable constraints.
public struct SchemaObjectProperty {
    let schema: Schema
    let nullability: Nullability? // Nullability does not apply for primitive types

    init(schema aSchema: Schema, nullability aNullability: Nullability?) {
        schema = aSchema
        nullability = aNullability
    }

    init(schema: Schema) {
        self.init(schema: schema, nullability: nil)
    }
}

extension Schema {
    func nonnullProperty() -> SchemaObjectProperty {
        return SchemaObjectProperty(schema: self, nullability: .nonnull)
    }

    func nullableProperty() -> SchemaObjectProperty {
        return SchemaObjectProperty(schema: self, nullability: .nullable)
    }
}

public struct SchemaObjectRoot: Equatable {
    let name: String
    let properties: [String: SchemaObjectProperty]
    let extends: URLSchemaReference?
    let algebraicTypeIdentifier: String?

    var typeIdentifier: String {
        return algebraicTypeIdentifier ?? name
    }
}

public func == (lhs: SchemaObjectRoot, rhs: SchemaObjectRoot) -> Bool {
    return lhs.name == rhs.name
}

extension SchemaObjectRoot: CustomDebugStringConvertible {
    public var debugDescription: String {
        return (["\(name)\n extends from \(String(describing: extends.map { $0.force()?.debugDescription }))\n"] + properties.map { (key, value) in "\t\(key): \(value.schema.debugDescription)\n" }).reduce("", +)
    }
}

public indirect enum Schema {
    case object(SchemaObjectRoot)
    case array(itemType: Schema?)
    case set(itemType: Schema?)
    case map(valueType: Schema?) // TODO: Should we have an option to specify the key type? (probably yes)
    case integer
    case float
    case boolean
    case string(format: StringFormatType?)
    case oneOf(types: [Schema]) // ADT
    case enumT(EnumType)
    case reference(with: URLSchemaReference)
}

typealias Property = (Parameter, SchemaObjectProperty)

extension Schema: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .array(itemType: let itemType):
            return "Array: \(itemType.debugDescription)"
        case .set(itemType: let itemType):
            return "Set: \(itemType.debugDescription)"
        case .object(let root):
            return "Object: \(root.debugDescription)"
        case .map(valueType: let valueType):
            return "Map: \(valueType as Optional)"
        case .integer:
            return "Integer"
        case .float:
            return "Float"
        case .boolean:
            return "Boolean"
        case .string:
            return "String"
        case .oneOf(types: let types):
            return (["OneOf"] + types.map { value in "\t\(value.debugDescription)\n" }).reduce("", +)
        case .enumT(let enumType):
            return "Enum: \(enumType)"
        case .reference(with: let ref):
            return "Reference to \(ref.url)"
        }
    }
}

extension Schema {
    // Computed Properties
    var title: String? {
        switch self {
        case .object(let rootObject):
            return rootObject.name
        default:
            return nil
        }
    }

    func extends() -> Schema? {
        switch self {
        case .object(let rootObject):
            return rootObject.extends.flatMap { $0.force() }
        default:
            return nil
        }
    }

    func deps() -> Set<URL> {
        switch self {
        case .object(let rootObject):
            let url: URL? = rootObject.extends?.url
            return (url.map { Set([$0]) } ?? Set()).union(
                    Set(
                        rootObject.properties.values.flatMap { (prop: SchemaObjectProperty) -> Set<URL> in
                            return prop.schema.deps()
                    }))
        case .array(itemType: let itemType), .set(itemType: let itemType):
            return itemType?.deps() ?? []
        case .map(valueType: let valueType):
            return valueType?.deps() ?? []
        case .integer, .float, .boolean, .string, .enumT:
            return []
        case .oneOf(types: let types):
            return types.map { type in type.deps() }.reduce([]) { $0.union($1) }
        case .reference(with: let ref):
            return [ref.url]
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
            case JSONType.string:
                if let enumValues = propertyInfo["enum"] as? [JSONObject], let defaultValue = propertyInfo["default"] as? String {
                    let enumVals = enumValues.map { EnumValue<String>(withObject: $0) }
                    let defaultVal = enumVals.first(where: { $0.defaultValue == defaultValue })
                    let maybeEnumVals: [EnumValue<String>]? = .some(enumVals)
                    return maybeEnumVals
                        .flatMap { (values: [EnumValue<String>]) in defaultVal.map { ($0, values) } }
                        .map { (defaultVal, enumVals) in
                            Schema.enumT(EnumType.string(enumVals, defaultValue: defaultVal))
                        }
                } else {
                    return Schema.string(format: (propertyInfo["format"] as? String).flatMap(StringFormatType.init))
                }
            case JSONType.array:
                if let unique = propertyInfo["unique"] as? String, unique == "true" {
                    return .set(itemType: (propertyInfo["items"] as? JSONObject)
                        .flatMap { propertyForType(propertyInfo: $0, source: source)})
                }

                return .array(itemType: (propertyInfo["items"] as? JSONObject)
                        .flatMap { propertyForType(propertyInfo: $0, source: source)})
            case JSONType.integer:
                if let enumValues = propertyInfo["enum"] as? [JSONObject] {
                    return Schema.enumT(EnumType.integer(enumValues.map { EnumValue<Int>(withObject: $0) }))
                } else {
                    return .integer
                }
            case JSONType.number:
                return .float
            case JSONType.boolean:
                return .boolean
            case JSONType.pointer:
                return (propertyInfo["$ref"] as? String).map { refStr in
                    let refUrl = decodeRef(from: source, with: refStr)
                    return .reference(with: URLSchemaReference(url: refUrl, force: { () -> Schema? in
                        loader.loadSchema(refUrl)
                    }))
                }
            case JSONType.object:
                let requiredProps = Set(propertyInfo["required"] as? [String] ?? [])
                if let propMap = propertyInfo["properties"] as? JSONObject, let objectTitle = title {
                    // Class
                    let optTuples: [Property?] = propMap.map { (key, value) -> (String, Schema?) in
                        let schemaOpt = (value as? JSONObject).flatMap {
                                propertyForType(propertyInfo: $0, source: source)
                        }
                        return (key, schemaOpt)
                        }.map { (name, optSchema) in optSchema.map {
                            (name, SchemaObjectProperty(schema: $0, nullability: $0.isObjCPrimitiveType ? nil : requiredProps.contains(name) ? .nonnull : .nullable))
                            }
                    }
                    let lifted: [Property]? = optTuples.reduce([], { (build: [Property]?, tupleOption: Property?) -> [Property]? in
                        build.flatMap { (bld: [Property]) -> [Property]? in tupleOption.map { bld + [$0] } }
                    })
                    let extendsDict: JSONObject? = propertyInfo["extends"] as? JSONObject
                    let extends: URLSchemaReference? = extendsDict
                        .flatMap { (obj: JSONObject) in
                            let refStr = obj["$ref"] as? String
                            return refStr.map { refStr in
                            let refUrl = decodeRef(from: source, with: refStr)
                            return URLSchemaReference(url: refUrl, force: {
                            loader.loadSchema(refUrl) })
                            }
                        }
                    return lifted.map { Schema.object(SchemaObjectRoot(name: objectTitle,
                                                                       properties: Dictionary(elements: $0),
                                                                       extends: extends,
                                                                       algebraicTypeIdentifier: propertyInfo["algebraicDataTypeIdentifier"] as? String)) }
                } else {
                    // Map type
                    return Schema.map(valueType: (propertyInfo["additionalProperties"] as? JSONObject)
                        .flatMap { propertyForType(propertyInfo: $0, source: source) })
                }
            case JSONType.polymorphic:
                return (propertyInfo["oneOf"] as? [JSONObject]) // [JSONObject]
                    .map { jsonObjs in jsonObjs.map { propertyForType(propertyInfo: $0, source: source) } } // [Schema?]?
                    .flatMap { schemas in schemas.reduce([], { (build: [Schema]?, tupleOption: Schema?) -> [Schema]? in
                        build.flatMap { (bld: [Schema]) -> [Schema]? in tupleOption.map { bld + [$0] } }
                    }) }
                    .map { Schema.oneOf(types: $0) }
            }

        }
        return propertyForType
    }
}
