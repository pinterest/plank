//
//  schema.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

typealias JSONObject = [String:AnyObject]

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

class ObjectSchemaProperty {
    let name: String
    let jsonType: JSONType
    let propInfo: JSONObject
    let sourceId: NSURL
    let enumValues: [JSONObject] // TODO: Create a type-safe struct to represent EnumValue
    let defaultValue: AnyObject?

    init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) {
        self.name = name
        self.jsonType = objectType
        self.propInfo = propertyInfo
        self.sourceId = sourceId
        if let enumValues = propertyInfo["enum"] as? [JSONObject] {

            self.enumValues = enumValues
        } else {
            self.enumValues = []
        }

        if let defaultVal = propertyInfo["default"] as AnyObject? {
            self.defaultValue = defaultVal
        } else {
            self.defaultValue = nil;
        }
    }

    class func propertyForJSONObject(json: JSONObject, var name: String = "", scopeUrl: NSURL) -> ObjectSchemaProperty {
        if let title = json["title"] as? String {
            name = title
        }

        // Check for "type"
        if let propTypeString = json["type"] as? String {
            if let propType = JSONType(rawValue: propTypeString) {
                return ObjectSchemaProperty.propertyForType(name, objectType: propType, propertyInfo: json, sourceId: scopeUrl)
            }
        }

        var sourceUrl = scopeUrl
        if let rawId = json["id"] as? String {
            if rawId.hasPrefix("http") {
                sourceUrl = NSURL(string: rawId)!
            } else {
                sourceUrl = NSURL(fileURLWithPath: rawId).URLByStandardizingPath!
            }
        }


        // Check for reference to relative or remote path.
        if let _ = json["$ref"] as? String {
            if sourceUrl != NSURL() {
                return ObjectSchemaPointerProperty(name: name, objectType: JSONType.Pointer,
                    propertyInfo: json, sourceId: sourceUrl)
            } else {
                assert(false) // Shouldn't be reached
            }
        }

        if let _ = json["oneOf"] as? [JSONObject] {
            return ObjectSchemaPolymorphicProperty(name: name, objectType: JSONType.Polymorphic, propertyInfo: json, sourceId: scopeUrl)
        }


        assert(false) // Shouldn't be reached
        let propType: JSONType = JSONType(rawValue: (json["type"] as? String)!)!
        return ObjectSchemaProperty.propertyForType(name, objectType: propType, propertyInfo: json, sourceId: scopeUrl)
    }

    class func propertyForType(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) -> ObjectSchemaProperty {
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

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) {
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
    var referencedClasses: [ObjectSchemaPointerProperty] {
        let seenReferences = NSMutableSet()

        var allReferences = Array<ObjectSchemaPointerProperty>()
        var propertyQueue = Array<ObjectSchemaProperty>()
        propertyQueue.appendContentsOf(self.properties)

        while propertyQueue.count > 0 {
            if let obj = propertyQueue.popLast() {
                switch obj {
                // References to other models defined in this object property list
                case let pointerObj as ObjectSchemaPointerProperty:
                    if !seenReferences.containsObject(pointerObj.ref) {
                        seenReferences.addObject(pointerObj.ref)
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
                    propertyQueue.appendContentsOf(polymorphicObj.oneOf)
                default: break
                }
            }
        }

        return allReferences
    }

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) {
        var id = sourceId
        if let rawId = propertyInfo["id"] as? String {
            if rawId.hasPrefix("http") {
                id = NSURL(string: rawId)!
            } else {
                id = NSURL(fileURLWithPath: rawId).URLByStandardizingPath!
            }
        }

        if let rawProperties = propertyInfo["properties"] as? Dictionary<String, AnyObject> {
            self.properties = rawProperties.keys.sort().map { (key: String) -> ObjectSchemaProperty in

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

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) {
        if let formatString = propertyInfo["format"] as? String {
            self.format = JSONStringFormatType(rawValue:formatString)
        } else {
            self.format = nil
        }
        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}

class ObjectSchemaPointerProperty: ObjectSchemaProperty {
    var ref: NSURL {
        get {

            if let refString = self.refString {
                if refString.hasPrefix("#") {
                    // Local URL
                    return NSURL(string:refString, relativeToURL:sourceId)!
                } else {
                    var baseUrl = sourceId.URLByDeletingLastPathComponent
                    if baseUrl!.path == "." {
                        baseUrl = NSURL(fileURLWithPath: (baseUrl?.path)!)
                    }
                    let lastPathComponentString = NSURL(string: refString)?.pathComponents?.last
                    return NSURL(string:lastPathComponentString!, relativeToURL:baseUrl)!
                }
            } else {
                assert(false)
                return NSURL()
            }
        }
    }

    private let refString: String?

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) {
        if let refString = propertyInfo["$ref"] as? String {
            self.refString = refString
        } else {
            self.refString = nil
            assert(false)
        }

        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}


class ObjectSchemaArrayProperty: ObjectSchemaProperty {
    let items: ObjectSchemaProperty?
    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId: NSURL) {
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

class SchemaLoader {
    static let sharedInstance = SchemaLoader()

    var refs: [NSURL:ObjectSchemaProperty]

    init() {
        self.refs = [NSURL:ObjectSchemaProperty]()
    }

    func loadSchema(schemaUrl: NSURL) -> ObjectSchemaProperty? {
        if let cachedValue = refs[schemaUrl] as ObjectSchemaProperty? {
            return cachedValue
        }

        // Checks for prefix of http to satisfy both http and https urls
        if schemaUrl.scheme.hasPrefix("http") {
            do {
                // Builds a URL with the access-token necessary to access the schema by appending a query parameter.
                let schemaUrlWithToken = NSURL(string: "\(schemaUrl.absoluteURL.absoluteString)?\(accessTokenString)")!
                if let data = NSURLSession.sharedSession().synchronousDataTaskWithUrl(schemaUrlWithToken) {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! [String:AnyObject]

                    if jsonResult["data"] !== NSNull() {
                        refs[schemaUrl] = ObjectSchemaProperty.propertyForJSONObject(jsonResult["data"] as! JSONObject, scopeUrl: schemaUrl)
                    }
                    // TODO (rmalik): Figure out if we should handle NSNull values differently for schemas.
                    // https://phabricator.pinadmin.com/T47
                    return refs[schemaUrl]
                }
            } catch {
                // TODO: Better failure handling and reporting
                // https://phabricator.pinadmin.com/T49
                assert(false)
            }
        } else {
            // Load from local file
            do {
                if let data = NSData(contentsOfFile: schemaUrl.path!) {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! [String:AnyObject]

                    refs[schemaUrl] = ObjectSchemaProperty.propertyForJSONObject(jsonResult, scopeUrl: schemaUrl)
                    return refs[schemaUrl]
                }
            } catch {
                // TODO: Better failure handling and reporting
                // https://phabricator.pinadmin.com/T49
                assert(false)
            }
        }
        return nil
    }
}
