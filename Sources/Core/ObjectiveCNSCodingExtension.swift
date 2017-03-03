//
//  ObjectiveCNSCodingExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/14/17.
//
//

import Foundation

extension ObjCModelRenderer {
    func renderInitWithCoder() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithCoder:(NSCoder *)aDecoder") {
            [
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                "if (!(self = [super initWithCoder:aDecoder])) { return self; }",
                self.properties.map(decodeStatement).joined(separator: "\n"),

                self.properties.map { (param, _) -> String in
                    "_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) = [aDecoder decodeIntForKey:\((param + "_dirty_property").objcLiteral())] & 0x1;"
                    }.joined(separator: "\n"),

                ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                    [renderPostInitNotification(type: "PIModelInitTypeDefault")]
                },
                "return self;"
            ]
        }
    }

    func renderEncodeWithCoder() -> ObjCIR.Method {
        return ObjCIR.method("- (void)encodeWithCoder:(NSCoder *)aCoder") {
            [
                self.isBaseClass ? "" : "[super encodeWithCoder:aCoder];",
                self.properties.map(encodeStatement).joined(separator: "\n"),
                self.properties.map { (param, _) -> String in
                    "[aCoder encodeInt:_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) forKey:\((param + "_dirty_property").objcLiteral())];"}.joined(separator: "\n")
                ].filter { $0 != "" }
        }
    }
}

extension ObjCADTRenderer {
    func renderInitWithCoder() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithCoder:(NSCoder *)aDecoder") {
            [
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                "if (!(self = [super initWithCoder:aDecoder])) { return self; }",
                self.properties.map(decodeStatement).joined(separator: "\n"),
                "return self;"
            ]
        }
    }

    func renderEncodeWithCoder() -> ObjCIR.Method {
        return ObjCIR.method("- (void)encodeWithCoder:(NSCoder *)aCoder") {
            [
                self.isBaseClass ? "" : "[super encodeWithCoder:aCoder];",
                self.properties.map(encodeStatement).joined(separator: "\n")
            ].filter { $0 != "" }
        }
    }
}

extension ObjCFileRenderer {

    func renderSupportsSecureCoding() -> ObjCIR.Method {
        return ObjCIR.method("+ (BOOL)supportsSecureCoding") { ["return YES;"] }
    }

    fileprivate func referencedObjectClasses(_ schema: Schema) -> Set<String> {
        switch schema {
        case .Array(itemType: .none):
            return Set(["NSArray"])
        case .Array(itemType: .some(let itemType)):
            return Set(["NSArray"]).union(referencedObjectClasses(itemType))
        case .Map(valueType: .none):
            return Set(["NSDictionary"])
        case .Map(valueType: .some(let valueType)):
            return Set(["NSDictionary"]).union(referencedObjectClasses(valueType))
        case .String(format: .none),
             .String(format: .some(.Email)),
             .String(format: .some(.Hostname)),
             .String(format: .some(.Ipv4)),
             .String(format: .some(.Ipv6)):
            return Set(["NSString"])
        case .String(format: .some(.DateTime)):
            return Set(["NSDate"])
        case .String(format: .some(.Uri)):
            return Set(["NSURL"])
        case .Integer, .Float, .Boolean, .Enum(_):
            return Set(["NSNumber"])
        case .Object(let objSchemaRoot):
            return Set([objSchemaRoot.className(with: self.params)])
        case .Reference(with: let fn):
            switch fn() {
            case .some(.Object(let schemaRoot)):
                return referencedObjectClasses(.Object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        case .OneOf(types: let schemaTypes):
            return schemaTypes.map(referencedObjectClasses).reduce(Set(), { s1, s2 in s1.union(s2) })
        }
    }

    fileprivate func decodeStatement(_ param: String, _ schema: Schema) -> String {
        let propIVarName = "_\(param.snakeCaseToPropertyName())"
        return "\(propIVarName) = " + { switch schema {
        case .Enum(_):
            return "[aDecoder decodeIntegerForKey:\(param.objcLiteral())];"
        case .Boolean:
            return "[aDecoder decodeBoolForKey:\(param.objcLiteral())];"
        case .Float:
            return "[aDecoder decodeDoubleForKey:\(param.objcLiteral())];"
        case .Integer:
            return "[aDecoder decodeIntegerForKey:\(param.objcLiteral())];"
        case .String(_), .Map(_), .Array(_), .OneOf(_), .Reference(_), .Object(_):
            let refObjectClasses = referencedObjectClasses(schema).map { "[\($0) class]" }
            let refObjectClassesString = refObjectClasses.count == 1 ? refObjectClasses.joined(separator: ",") : "[NSSet setWithArray:\(refObjectClasses.objcLiteral())]"
            if refObjectClasses.count == 0 { fatalError("Can't determine class for decode for \(schema)") }
            if refObjectClasses.count == 1 {
                return "[aDecoder decodeObjectOfClass:\(refObjectClassesString) forKey:\(param.objcLiteral())];"
            } else {
                return "[aDecoder decodeObjectOfClasses:\(refObjectClassesString) forKey:\(param.objcLiteral())];"
            }
            }
            }()
    }

    func encodeStatement(_ param: String, _ schema: Schema) -> String {
        let propGetter = "self.\(param.snakeCaseToPropertyName())"
        switch schema {
        case .Enum(_):
            return "[aCoder encodeInteger:\(propGetter) forKey:\(param.objcLiteral())];"
        case .Boolean:
            return "[aCoder encodeBool:\(propGetter) forKey:\(param.objcLiteral())];"
        case .Float:
            return "[aCoder encodeDouble:\(propGetter) forKey:\(param.objcLiteral())];"
        case .Integer:
            return "[aCoder encodeInteger:\(propGetter) forKey:\(param.objcLiteral())];"
        case .String(_), .Map(_), .Array(_), .OneOf(_), .Reference(_), .Object(_):
            return "[aCoder encodeObject:\(propGetter) forKey:\(param.objcLiteral())];"
        }
    }
}
