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
                    [renderPostInitNotification(type: "PlankModelInitTypeDefault")]
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
        case .array(itemType: .none):
            return Set(["NSArray"])
        case .array(itemType: .some(let itemType)):
            return Set(["NSArray"]).union(referencedObjectClasses(itemType))
        case .map(valueType: .none):
            return Set(["NSDictionary"])
        case .map(valueType: .some(let valueType)):
            return Set(["NSDictionary"]).union(referencedObjectClasses(valueType))
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return Set(["NSString"])
        case .string(format: .some(.dateTime)):
            return Set(["NSDate"])
        case .string(format: .some(.uri)):
            return Set(["NSURL"])
        case .integer, .float, .boolean, .enumT(_):
            return Set(["NSNumber"])
        case .object(let objSchemaRoot):
            return Set([objSchemaRoot.className(with: self.params)])
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return referencedObjectClasses(.object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        case .oneOf(types: let schemaTypes):
            return schemaTypes.map(referencedObjectClasses).reduce(Set(), { set1, set2 in set1.union(set2) })
        }
    }

    fileprivate func decodeStatement(_ param: String, _ schema: Schema) -> String {
        let propIVarName = "_\(param.snakeCaseToPropertyName())"
        return "\(propIVarName) = " + { switch schema {
        case .enumT(_):
            return "[aDecoder decodeIntegerForKey:\(param.objcLiteral())];"
        case .boolean:
            return "[aDecoder decodeBoolForKey:\(param.objcLiteral())];"
        case .float:
            return "[aDecoder decodeDoubleForKey:\(param.objcLiteral())];"
        case .integer:
            return "[aDecoder decodeIntegerForKey:\(param.objcLiteral())];"
        case .string(_), .map(_), .array(_), .oneOf(_), .reference(_), .object(_):
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
        case .enumT(_):
            return "[aCoder encodeInteger:\(propGetter) forKey:\(param.objcLiteral())];"
        case .boolean:
            return "[aCoder encodeBool:\(propGetter) forKey:\(param.objcLiteral())];"
        case .float:
            return "[aCoder encodeDouble:\(propGetter) forKey:\(param.objcLiteral())];"
        case .integer:
            return "[aCoder encodeInteger:\(propGetter) forKey:\(param.objcLiteral())];"
        case .string(_), .map(_), .array(_), .oneOf(_), .reference(_), .object(_):
            return "[aCoder encodeObject:\(propGetter) forKey:\(param.objcLiteral())];"
        }
    }
}
