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
    case Null = "null"
    case Pointer = "$ref" // Used for combining schemas via references.
    case Polymorphic = "oneOf" // JSONType composed of other JSONTypes
}

public enum JSONStringFormatType: String {
    case DateTime = "date-time"  // Date representation, as defined by RFC 3339, section 5.6.
    case Email = "email"  // Internet email address, see RFC 5322, section 3.4.1.
    case Hostname = "hostname"  // Internet host name, see RFC 1034, section 3.1.
    case Ipv4 = "ipv4"  // IPv4 address, according to dotted-quad ABNF syntax as defined in RFC 2673, section 3.2.
    case Ipv6 = "ipv6"  // IPv6 address, as defined in RFC 2373, section 2.2.
    case Uri = "uri"  // A universal resource identifier (URI), according to RFC3986.
}

struct JSONParseError: Error {}

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

class ObjectSchemaProperty {
    let name: String
    let jsonType: JSONType
    let propInfo: JSONObject
    let sourceId: URL
    let enumValues: [EnumValue<AnyObject>] // TODO: Improve type constraints beyond AnyObject here.
    let defaultValue: Any?
    let descriptionString: String?
    let algebraicDataTypeIdentifier: String
    var isModelProperty: Bool {
        return false
    }

    init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) {
        self.name = name
        self.jsonType = objectType
        self.propInfo = propertyInfo
        self.sourceId = sourceId
        self.enumValues = ((propertyInfo["enum"] as? [JSONObject]) ?? []).flatMap {
            if let val = try? EnumValue<AnyObject>(object: $0) {
                return val
            }
            assertionFailure("Invalid enumeration value in \(name) schema property: \($0)")
            return nil
        }
        self.algebraicDataTypeIdentifier = propertyInfo["algebraicDataTypeIdentifier"] as? String ?? name
        self.defaultValue = propertyInfo["default"] ?? nil
        self.descriptionString = propertyInfo["description"] as? String
    }

    class func propertyForJSONObject(_ json: JSONObject, name: String = "", scopeUrl: URL) -> ObjectSchemaProperty {
        var propertyName = name
        if let title = json["title"] as? String {
            propertyName = title
        }

        // Check for "type"
        if let propTypeString = json["type"] as? String, let propType = JSONType(rawValue: propTypeString) {
            return ObjectSchemaProperty.propertyForType(propertyName, objectType: propType, propertyInfo: json, sourceId: scopeUrl)
        }

        var sourceUrl = scopeUrl
        if let rawId = json["id"] as? String {
            if rawId.hasPrefix("http") {
                sourceUrl = URL(string: rawId)!
            } else {
                sourceUrl = URL(fileURLWithPath: rawId).standardizedFileURL
            }
        }


        // Check for reference to relative or remote path.
        if let _ = json["$ref"] as? String {
            if sourceUrl.absoluteString != "" {
                return ObjectSchemaPointerProperty(name: propertyName, objectType: JSONType.Pointer,
                    propertyInfo: json, sourceId: sourceUrl)
            } else {
                assert(false) // Shouldn't be reached
            }
        }

        if let _ = json["oneOf"] as? [JSONObject] {
            return ObjectSchemaPolymorphicProperty(name: propertyName, objectType: JSONType.Polymorphic, propertyInfo: json, sourceId: scopeUrl)
        }


        assert(false) // Shouldn't be reached
        let propType: JSONType = JSONType(rawValue: (json["type"] as? String)!)!
        return ObjectSchemaProperty.propertyForType(propertyName, objectType: propType, propertyInfo: json, sourceId: scopeUrl)
    }

    class func propertyForType(_ name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) -> ObjectSchemaProperty {
        switch objectType {
        case JSONType.String:
            return ObjectSchemaStringProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        case JSONType.Array:
            return ObjectSchemaArrayProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        case JSONType.Integer, JSONType.Number:
            return ObjectSchemaNumberProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        case JSONType.Boolean:
            return ObjectSchemaBooleanProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        case JSONType.Pointer:
            return ObjectSchemaPointerProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        case JSONType.Object:
            return ObjectSchemaObjectProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        case JSONType.Polymorphic:
            return ObjectSchemaPolymorphicProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        default:
            assert(false)
            return ObjectSchemaObjectProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        }
    }
}

class ObjectSchemaPolymorphicProperty: ObjectSchemaProperty {
    let oneOf: [ObjectSchemaProperty]
    override var isModelProperty: Bool {
        return oneOf.filter({ $0.isModelProperty }).count == oneOf.count;
    }

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) {
        if let oneOfValues = propertyInfo["oneOf"] as? [JSONObject] {
            self.oneOf = oneOfValues.map { ObjectSchemaProperty.propertyForJSONObject($0, scopeUrl: sourceId) }
        } else {
            assert(false, "Insufficient amount of items specified for oneOf")
            self.oneOf = []
        }
        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }

}

class ObjectSchemaObjectProperty: ObjectSchemaProperty {
    let definitions: [ObjectSchemaProperty]
    let properties: [ObjectSchemaProperty]
    let additionalProperties: ObjectSchemaProperty?
    let extends: ObjectSchemaPointerProperty?

    var referencedClasses: [ObjectSchemaPointerProperty] {
        let seenReferences = NSMutableSet()

        var allReferences = Array<ObjectSchemaPointerProperty>()
        var propertyQueue = Array<ObjectSchemaProperty>()
        propertyQueue.append(contentsOf: self.properties)

        while propertyQueue.count > 0 {
            if let obj = propertyQueue.popLast() {
                switch obj {
                // References to other models defined in this object property list
                case let pointerObj as ObjectSchemaPointerProperty:
                    if !seenReferences.contains(pointerObj.ref) {
                        seenReferences.add(pointerObj.ref)
                        allReferences.append(pointerObj)
                    }
                // References to other models defined through Generics on Collection Types (Array, Object)
                case let arrayObj as ObjectSchemaArrayProperty:
                    if let items = arrayObj.items {
                        propertyQueue.append(items)
                    }
                case let dictObj as ObjectSchemaObjectProperty:
                    if let additionalProps = dictObj.additionalProperties {
                        propertyQueue.append(additionalProps)

                    }
                case let polymorphicObj as ObjectSchemaPolymorphicProperty:
                    propertyQueue.append(contentsOf: polymorphicObj.oneOf)
                default: break
                }
            }
        }



        return allReferences
    }

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) {
        var id = sourceId
        if let rawId = propertyInfo["id"] as? String {
            if rawId.hasPrefix("http") {
                id = URL(string: rawId)!
            } else {
                id = URL(string: rawId, relativeTo: sourceId)!
            }
        }

        if let rawProperties = propertyInfo["properties"] as? JSONObject {
            self.properties = rawProperties.keys.sorted().map { (key: String) -> ObjectSchemaProperty in

                let propInfo = (rawProperties[key] as? JSONObject)!
                // Check for "type"
                if let propTypeString = propInfo["type"] as? String {
                    if let propType = JSONType(rawValue: propTypeString) {
                        return ObjectSchemaProperty.propertyForType(key, objectType: propType, propertyInfo: propInfo, sourceId: id)
                    }
                }

                // Check for reference to relative or remote path.
                if let _ = propInfo["$ref"] as? String {
                    return ObjectSchemaPointerProperty(name: key, objectType: JSONType.Pointer, propertyInfo: propInfo, sourceId: id)
                }

                if let _ = propInfo["oneOf"] as? [JSONObject] {
                    return ObjectSchemaPolymorphicProperty(name: key, objectType: JSONType.Polymorphic, propertyInfo: propInfo, sourceId: id)
                }

                // MARK: Shouldn't reach here
                assert(false, "Unsupported property definition for \(key)")
                let propType: JSONType = JSONType(rawValue: (propInfo["type"] as? String)!)!
                return ObjectSchemaProperty.propertyForType(key, objectType: propType, propertyInfo: propInfo, sourceId: id)
            }
        } else {
            self.properties = [ObjectSchemaProperty]()
        }

        // TODO: Parse definitions
        // https://phabricator.pinadmin.com/T48
        self.definitions = [ObjectSchemaProperty]()

        if let rawItems = propertyInfo["additionalProperties"] as? JSONObject {
            self.additionalProperties = ObjectSchemaProperty.propertyForJSONObject(rawItems, scopeUrl: id)
        } else {
            self.additionalProperties = nil
        }

        if let rawExtendsFrom = propertyInfo["extends"] as? JSONObject {
            if let extendsFromSchema = ObjectSchemaProperty.propertyForJSONObject(rawExtendsFrom, scopeUrl: id) as? ObjectSchemaPointerProperty {
                self.extends = extendsFromSchema
            } else {
                assert(false, "Invalid extends schema specified in \(id)")
                self.extends = nil;
            }
        } else {
            self.extends = nil;
        }

        // Use title if available as the object name, fall-back to the provided name in this constructor.
        if let objectName = propertyInfo["title"] as? String {
            super.init(name: objectName, objectType: objectType, propertyInfo: propertyInfo, sourceId: id)
        } else {
            super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: id)
        }
    }
}


class ObjectSchemaStringProperty: ObjectSchemaProperty {
    let format: JSONStringFormatType?

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) {
        if let formatString = propertyInfo["format"] as? String {
            self.format = JSONStringFormatType(rawValue:formatString)
        } else {
            self.format = nil
        }
        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}

class ObjectSchemaPointerProperty: ObjectSchemaProperty {
    var ref: URL {
        get {

            if let refString = self.refString {
                if refString.hasPrefix("#") {
                    // Local URL
                    return URL(string:refString, relativeTo:sourceId)!
                } else {
                    var baseUrl = sourceId.deletingLastPathComponent()
                    if baseUrl.path == "." {
                        baseUrl = URL(fileURLWithPath: (baseUrl.path))
                    }
                    let lastPathComponentString = URL(string: refString)?.pathComponents.last
                    return URL(string:lastPathComponentString!, relativeTo:baseUrl)!
                }
            } else {
                assert(false)
                return URL(fileURLWithPath: "")
            }
        }
    }
    override var isModelProperty: Bool {
        return true
    }

    fileprivate let refString: String?

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) {
        if let refString = propertyInfo["$ref"] as? String {
            self.refString = refString
        } else {
            self.refString = nil
            assert(false)
        }

        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}


// Explore using NSOrderedSet as the type if "uniqueItems": true is present.
class ObjectSchemaArrayProperty: ObjectSchemaProperty {
    let items: ObjectSchemaProperty?
    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: URL) {
        if let rawItems = propertyInfo["items"] as? JSONObject {
            self.items = ObjectSchemaProperty.propertyForJSONObject(rawItems, scopeUrl: sourceId)
        } else {
            self.items = nil
        }
        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}

class ObjectSchemaBooleanProperty: ObjectSchemaProperty {}

class ObjectSchemaNumberProperty: ObjectSchemaProperty {}

class ObjectSchemaNullProperty: ObjectSchemaProperty {}
