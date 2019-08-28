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
    func renderHash(_ booleanIVarName: String = "") -> ObjCIR.Method {
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
                return !booleanIVarName.isEmpty ?
                    "(_\(booleanIVarName).\(booleanPropertyOption(propertyName: param, className: className)) ? 1231 : 1237)" :
                    "(_\(param) ? 1231 : 1237)"
            case let .reference(with: ref):
                switch ref.force() {
                case let .some(.object(schemaRoot)):
                    return schemaHashStatement(with: param, for: .object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            default:
                return "[_\(param) hash]"
            }
        }

        let rootHashStatement = isBaseClass ? ["17"] : ["[super hash]"]
        let propReturnStatements = rootHashStatement + properties.map { param, prop -> String in
            let formattedParam = Languages.objectiveC.snakeCaseToPropertyName(param)
            return schemaHashStatement(with: formattedParam, for: prop.schema)
        }

        return ObjCIR.method("- (NSUInteger)hash") { [
            "NSUInteger subhashes[] = {",
            -->[propReturnStatements.joined(separator: ",\n")],
            "};",
            "return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));",
        ] }
    }

    // MARK: Equality Methods inspired from NSHipster article on Equality: http://nshipster.com/equality/

    func renderIsEqualToClass(_ booleanIVarName: String = "") -> ObjCIR.Method {
        func schemaIsEqualStatement(with param: Parameter, for schema: Schema) -> String {
            switch schema {
            case .integer, .float, .enumT, .boolean:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return ""
            case .array:
                return ObjCIR.msg("_\(param)", ("isEqualToArray", "anObject.\(param)"))
            case .set:
                return ObjCIR.msg("_\(param)", ("isEqualToSet", "anObject.\(param)"))
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
            case .oneOf(types: _), .object, .string(format: .some(.uri)):
                return ObjCIR.msg("_\(param)", ("isEqual", "anObject.\(param)"))
            case let .reference(with: ref):
                switch ref.force() {
                case let .some(.object(schemaRoot)):
                    return schemaIsEqualStatement(with: param, for: .object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            }
        }

        // Performance optimization - compare primitives before resorting to more expensive `isEqual` calls
        let sortedProps = properties.sorted { arg1, _ in
            arg1.1.schema.isPrimitiveType
        }

        let propReturnStmts = sortedProps.map { param, prop -> String in
            let formattedParam = Languages.objectiveC.snakeCaseToPropertyName(param)
            switch prop.schema {
            case .boolean:
                if booleanIVarName.isEmpty {
                    fallthrough
                } else {
                    return "_\(booleanIVarName).\(booleanPropertyOption(propertyName: param, className: self.className)) == anObject.\(formattedParam)"
                }
            default:
                let pointerEqStmt = "_\(formattedParam) == anObject.\(formattedParam)"
                let deepEqStmt = schemaIsEqualStatement(with: formattedParam, for: prop.schema)
                return [pointerEqStmt, deepEqStmt].filter { $0 != "" }.joined(separator: " || ")
            }
        }

        func parentName(_ schema: Schema?) -> String? {
            switch schema {
            case let .some(.object(root)):
                return root.className(with: GenerationParameters())
            case let .some(.reference(with: ref)):
                return parentName(ref.force())
            default:
                return nil
            }
        }

        let superInvocation = parentName(parentDescriptor).map { ["[super isEqualTo\($0):anObject]"] } ?? []
        return ObjCIR.method("- (BOOL)isEqualTo\(Languages.objectiveC.snakeCaseToCamelCase(rootSchema.name)):(\(className) *)anObject") {
            [
                "return (",
                -->[(["anObject != nil"] + superInvocation + propReturnStmts)
                    .map { "(\($0))" }.joined(separator: " &&\n")],
                ");",
            ]
        }
    }

    func renderIsEqual() -> ObjCIR.Method {
        return ObjCIR.method("- (BOOL)isEqual:(id)anObject") {
            [
                ObjCIR.ifStmt("self == anObject") { ["return YES;"] },
                self.isBaseClass ? "" : ObjCIR.ifStmt("[super isEqual:anObject] == NO") { ["return NO;"] },
                ObjCIR.ifStmt("[anObject isKindOfClass:[\(self.className) class]] == NO") { ["return NO;"] },
                "return [self isEqualTo\(Languages.objectiveC.snakeCaseToCamelCase(self.rootSchema.name)):anObject];",
            ].filter { $0 != "" }
        }
    }
}
