//
//  ObjectiveCEqualityExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/14/17.
//
//

import Foundation

extension ObjCFileRenderer {

    // MARK: Hash Method - Inspired from Mike Ash article on Equality / Hashing
    // https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
    func renderHash() -> ObjCIR.Method {
        func schemaHashStatement(with param: Parameter, for schema: Schema) -> String {
            switch schema {
            case .Enum(_), .Integer:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return "(NSUInteger)_\(param)"
            case .Float:
                return " [@(_\(param)) hash]"
            case .Boolean:
                // Values 1231 for true and 1237 for false are adopted from the Java hashCode specification
                // http://docs.oracle.com/javase/7/docs/api/java/lang/Boolean.html#hashCode
                return "(_\(param) ? 1231 : 1237)"
            case .Reference(with: let ref):
                switch ref.force() {
                case .some(.Object(let schemaRoot)):
                    return schemaHashStatement(with: param, for: .Object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            default:
                return "[_\(param) hash]"
            }
        }

        let rootHashStatement = self.isBaseClass ? ["17"] : ["[super hash]"]
        let propReturnStatements = rootHashStatement + self.properties.map { param, schema -> String in
            let formattedParam = param.snakeCaseToPropertyName()
            return schemaHashStatement(with: formattedParam, for: schema)
        }

        return ObjCIR.method("- (NSUInteger)hash") {[
            "NSUInteger subhashes[] = {",
            -->[propReturnStatements.joined(separator: ",\n")],
            "};",
            "return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));"
        ]}
    }

    // MARK: Equality Methods inspired from NSHipster article on Equality: http://nshipster.com/equality/
    func renderIsEqualToClass() -> ObjCIR.Method {
        func schemaIsEqualStatement(with param: Parameter, for schema: Schema) -> String {
            switch schema {
            case .Integer, .Float, .Enum(_), .Boolean:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return ""
            case .Map(_):
                return ObjCIR.msg("_\(param)", ("isEqualToDictionary", "anObject.\(param)"))
            case .String(format: .some(.DateTime)):
                return ObjCIR.msg("_\(param)", ("isEqualToDate", "anObject.\(param)"))
            case .String(format: .none),
                 .String(format: .some(.Email)),
                 .String(format: .some(.Hostname)),
                 .String(format: .some(.Ipv4)),
                 .String(format: .some(.Ipv6)):
                return ObjCIR.msg("_\(param)", ("isEqualToString", "anObject.\(param)"))
            case .OneOf(types:_), .Object(_), .Array(_), .String(format: .some(.Uri)):
                return ObjCIR.msg("_\(param)", ("isEqual", "anObject.\(param)"))
            case .Reference(with: let ref):
                switch ref.force() {
                case .some(.Object(let schemaRoot)):
                    return schemaIsEqualStatement(with: param, for: .Object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            }
        }

        // Performance optimization - compare primitives before resorting to more expensive `isEqual` calls
        let sortedProps = self.properties.sorted { $0.0.1.isObjCPrimitiveType }

        let propReturnStmts = sortedProps.map { param, schema -> String in
            let formattedParam = param.snakeCaseToPropertyName()
            let pointerEqStmt = "_\(formattedParam) == anObject.\(formattedParam)"
            let deepEqStmt = schemaIsEqualStatement(with: formattedParam, for: schema)
            return [pointerEqStmt, deepEqStmt].filter { $0 != "" }.joined(separator: " || ")
        }

        return ObjCIR.method("- (BOOL)isEqualTo\(self.rootSchema.name.snakeCaseToCamelCase()):(\(self.className) *)anObject") {
            [
                "return (",
                -->[(["anObject != nil", "self == anObject"] + propReturnStmts)
                    .map { "(\($0))" }.joined(separator: " &&\n")],
                ");"
            ]
        }
    }

    func renderIsEqual() -> ObjCIR.Method {
        return ObjCIR.method("- (BOOL)isEqual:(id)anObject") {
            [
                ObjCIR.ifStmt("self == anObject") { ["return YES;"] },
                self.isBaseClass ? "" : ObjCIR.ifStmt("[super isEqual:anObject] == NO") { ["return NO;"] },
                ObjCIR.ifStmt("[anObject isKindOfClass:[\(self.className) class]] == NO") { ["return NO;"] },
                "return [self isEqualTo\(self.rootSchema.name.snakeCaseToCamelCase()):anObject];"
                ].filter { $0 != "" }
        }
    }
}
