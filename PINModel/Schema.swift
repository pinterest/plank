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
    let propInfo : JSONObject
    let sourceId : NSURL

    init(name : String, objectType: JSONType, propertyInfo : JSONObject, sourceId : NSURL) {
        self.name = name
        self.jsonType = objectType
        self.propInfo = propertyInfo
        self.sourceId = sourceId
    }


    class func propertyForJSONObject(json: JSONObject, var name: String = "", scopeUrl : NSURL) -> ObjectSchemaProperty {
        if let title = json["title"] as? String {
            name = title
        }

        // Check for "type"
        if let propTypeString = json["type"] as? String {
            if let propType = JSONType(rawValue: propTypeString) {
                return ObjectSchemaProperty.propertyForType(name, objectType: propType, propertyInfo: json, sourceId: scopeUrl)
            }
        }

        // Check for reference to relative or remote path.
        if let _ = json["$ref"] as? String {
            if scopeUrl != NSURL() {
                return ObjectSchemaPointerProperty(name: name, objectType: JSONType.Pointer,
                    propertyInfo: json, sourceId: scopeUrl)
            } else if let rawId = json["id"] as? String {
                if rawId.hasPrefix("http") {
                    return ObjectSchemaPointerProperty(name: name, objectType: JSONType.Pointer,
                        propertyInfo: json, sourceId: NSURL(string: rawId)!)
                } else {
                    return ObjectSchemaPointerProperty(name: name, objectType: JSONType.Pointer,
                        propertyInfo: json, sourceId: NSURL(fileURLWithPath: rawId.stringByStandardizingPath))
                }
            } else {
                assert(false) // Shouldn't be reached
                return ObjectSchemaPointerProperty(name: name, objectType: JSONType.Pointer,
                    propertyInfo: json, sourceId: NSURL())
            }
        }


        // MARK: Shouldn't reach here
        assert(false) // Shouldn't be reached
        let propType : JSONType = JSONType(rawValue: (json["type"] as? String)!)!
        return ObjectSchemaProperty.propertyForType(name, objectType: propType, propertyInfo: json, sourceId: scopeUrl)
    }

    class func propertyForType(name: String, objectType : JSONType, propertyInfo : JSONObject, sourceId: NSURL) -> ObjectSchemaProperty {
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
        default:
            assert(false)
            return ObjectSchemaObjectProperty(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
        }
    }
}

class ObjectSchemaObjectProperty : ObjectSchemaProperty {
    let definitions : [ObjectSchemaProperty]
    let properties : [ObjectSchemaProperty]
    let additionalProperties : ObjectSchemaProperty?
    var referencedClasses : [ObjectSchemaPointerProperty] {
        let seenReferences = NSMutableSet()
        let allReferences : [ObjectSchemaPointerProperty] = properties.flatMap({ (obj : ObjectSchemaProperty) -> ObjectSchemaPointerProperty? in
            // References to other models defined in this object property list
            if obj is ObjectSchemaPointerProperty {
                let pointerObj = obj as! ObjectSchemaPointerProperty
                if (seenReferences.containsObject(pointerObj.ref)) {
                    return nil
                }
                seenReferences.addObject(pointerObj.ref)
                return obj as? ObjectSchemaPointerProperty
            }

            // References to other models defined through Generics on Collection Types (Array, Object)
            if obj is ObjectSchemaArrayProperty {
                if let arrayObj = obj as? ObjectSchemaArrayProperty {
                    if let arrayObjItems = arrayObj.items as ObjectSchemaProperty? {
                        if arrayObjItems.jsonType == JSONType.Pointer {
                            let pointerObj = arrayObjItems as! ObjectSchemaPointerProperty
                            if (seenReferences.containsObject(pointerObj.ref)) {
                                return nil
                            }
                            seenReferences.addObject(pointerObj.ref)
                            return arrayObjItems as? ObjectSchemaPointerProperty
                        }
                    }
                }
            }

            if obj is ObjectSchemaObjectProperty {
                if let dictObj = obj as? ObjectSchemaObjectProperty {
                    if let additionalProperties = dictObj.additionalProperties as ObjectSchemaProperty? {
                        if additionalProperties.jsonType == JSONType.Pointer {
                            let pointerObj = additionalProperties as! ObjectSchemaPointerProperty
                            if (seenReferences.containsObject(pointerObj.ref)) {
                                return nil
                            }
                            seenReferences.addObject(pointerObj.ref)
                            return additionalProperties as? ObjectSchemaPointerProperty
                        }
                    }
                }
            }

            return nil
        })

        return allReferences
    }

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId : NSURL) {
        var id = sourceId
        if let rawId = propertyInfo["id"] as? String {
            if rawId.hasPrefix("http") {
                id = NSURL(string: rawId.stringByStandardizingPath)!
            } else {
                id = NSURL(fileURLWithPath: rawId.stringByStandardizingPath)
            }
        }

        if let rawProperties = propertyInfo["properties"] as? Dictionary<String, AnyObject> {
            self.properties = rawProperties.keys.sort().map { (key : String) -> ObjectSchemaProperty in

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

                // MARK: Shouldn't reach here
                let propType : JSONType = JSONType(rawValue: (propInfo["type"] as? String)!)!
                return ObjectSchemaProperty.propertyForType(key, objectType: propType, propertyInfo: propInfo, sourceId: id)
            }
        } else {
            self.properties = [ObjectSchemaProperty]()
        }

        // TODO: Parse definitions
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


class ObjectSchemaStringProperty : ObjectSchemaProperty {
    let format : JSONStringFormatType?

    override init(name : String, objectType: JSONType, propertyInfo : JSONObject, sourceId : NSURL) {
        if let formatString = propertyInfo["format"] as? String {
            self.format = JSONStringFormatType(rawValue:formatString)
        } else {
            self.format = nil
        }
        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId : sourceId)
    }
}

class ObjectSchemaPointerProperty : ObjectSchemaProperty {
    var ref : NSURL {
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
                    return NSURL(string:refString, relativeToURL:baseUrl)!
                }
            } else {
                assert(false)
                return NSURL()
            }
        }
    }

    private let refString : String?

    override init(name: String, objectType: JSONType, propertyInfo: JSONObject, sourceId : NSURL) {
        if let refString = propertyInfo["$ref"] as? String {
            self.refString = refString
        } else {
            self.refString = nil
            assert(false)
        }

        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}


class ObjectSchemaArrayProperty : ObjectSchemaProperty {
    let items : ObjectSchemaProperty?
    override init(name : String, objectType: JSONType, propertyInfo : JSONObject, sourceId : NSURL) {
        if let rawItems = propertyInfo["items"] as? JSONObject {
            self.items = ObjectSchemaProperty.propertyForJSONObject(rawItems, scopeUrl : sourceId)
        } else {
            self.items = nil
        }
        super.init(name: name, objectType: objectType, propertyInfo: propertyInfo, sourceId: sourceId)
    }
}



class ObjectSchemaBooleanProperty : ObjectSchemaProperty {}
class ObjectSchemaNumberProperty : ObjectSchemaProperty {}
class ObjectSchemaNullProperty : ObjectSchemaProperty {}

class SchemaLoader {
    static let sharedInstance = SchemaLoader()

    var refs : [NSURL:ObjectSchemaProperty]

    init() {
        self.refs = [NSURL:ObjectSchemaProperty]()
    }

    func loadSchema(schemaUrl : NSURL) -> ObjectSchemaProperty? {
        if let cachedValue = refs[schemaUrl] as ObjectSchemaProperty? {
            return cachedValue
        }

        if schemaUrl.scheme.hasPrefix("http") {
            // TODO: Load schema from the network.
            assert(false)
        } else {
            // Load from local file
            do {
                if let data = NSData(contentsOfFile: schemaUrl.path!) {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! [String:AnyObject]

                    refs[schemaUrl] = ObjectSchemaProperty.propertyForJSONObject(jsonResult, scopeUrl : schemaUrl)
                    return refs[schemaUrl]
                }
            } catch {
                // TODO: Better failure handling and reporting
                assert(false)
            }
        }
        return nil
    }
}
