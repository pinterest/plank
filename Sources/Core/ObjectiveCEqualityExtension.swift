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
            case .enumT, .integer:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return "(NSUInteger)_\(param)"
            case .float:
                return " [@(_\(param)) hash]"
            case .boolean:
                // Values 1231 for true and 1237 for false are adopted from the Java hashCode specification
                // http://docs.oracle.com/javase/7/docs/api/java/lang/Boolean.html#hashCode
                return "(_\(param) ? 1231 : 1237)"
            case .reference(with: let ref):
                switch ref.force() {
                case .some(.object(let schemaRoot)):
                    return schemaHashStatement(with: param, for: .object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            default:
                return "[_\(param) hash]"
            }
        }

        let rootHashStatement = self.isBaseClass ? ["17"] : ["[super hash]"]
        let propReturnStatements = rootHashStatement + self.properties.map { param, prop -> String in
            let formattedParam = param.snakeCaseToPropertyName()
            return schemaHashStatement(with: formattedParam, for: prop.schema)
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
            case .integer, .float, .enumT, .boolean:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return ""
            case .array:
                return ObjCIR.msg("_\(param)", ("isEqualToArray", "anObject.\(param)"))
            case .map:
                return ObjCIR.msg("_\(param)", ("isEqualToDictionary", "anObject.\(param)"))
            case .string(format: .some(.dateTime)):
                return ObjCIR.msg("_\(param)", ("isEqualToDate", "anObject.\(param)"))
            case .string(format: .none),
                 .string(format: .some(.email)),
                 .string(format: .some(.hostname)),
                 .string(format: .some(.ipv4)),
                 .string(format: .some(.ipv6)):
                return ObjCIR.msg("_\(param)", ("isEqualToString", "anObject.\(param)"))
            case .oneOf(types:_), .object, .string(format: .some(.uri)):
                return ObjCIR.msg("_\(param)", ("isEqual", "anObject.\(param)"))
            case .reference(with: let ref):
                switch ref.force() {
                case .some(.object(let schemaRoot)):
                    return schemaIsEqualStatement(with: param, for: .object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            }
        }

        // Performance optimization - compare primitives before resorting to more expensive `isEqual` calls
        let sortedProps = self.properties.sorted { (t1, _) in
            t1.1.schema.isObjCPrimitiveType
        }

        let propReturnStmts = sortedProps.map { param, prop -> String in
            let formattedParam = param.snakeCaseToPropertyName()
            let pointerEqStmt = "_\(formattedParam) == anObject.\(formattedParam)"
            let deepEqStmt = schemaIsEqualStatement(with: formattedParam, for: prop.schema)
            return [pointerEqStmt, deepEqStmt].filter { $0 != "" }.joined(separator: " || ")
        }

        return ObjCIR.method("- (BOOL)isEqualTo\(self.rootSchema.name.snakeCaseToCamelCase()):(\(self.className) *)anObject") {
            [
                "return (",
                -->[(["anObject != nil"] + propReturnStmts)
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
