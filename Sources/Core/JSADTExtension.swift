//
//  JSADTExtension.swift
//  plank
//
//  Created by Michael Schneider
//
//

import Foundation

extension JSModelRenderer {

    public static func adtVariantTypeName(className: String, property: String) -> String {
        return "\(className)\(property.snakeCaseToCamelCase())Type"
    }

    public static func adtCaseTypeName(_ aSchema: Schema) -> String {
        switch aSchema {
        case .object(let objectRoot):
            // Intentionally drop prefix
            return "\(objectRoot.className(with: [:]))Type"
        case .reference(with: let ref):
            return ref.force().map(adtCaseTypeName) ?? {
                assert(false, "TODO: Forward optional across methods")
                return ""
                }()
        case .float: return "number"
        case .integer: return "number"
        case .enumT(.integer): return ""  // TODO: Not supported at the moment
        case .boolean: return "boolean"
        case .array(itemType: _): return "Array<*>"
        case .map(valueType: .none): return "{}"
        case .map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "{ +[string]: number } /* \(valueType.debugDescription) */"
        case .map(valueType: .some(let valueType)):
            return "{ +[string]: \(adtCaseTypeName(valueType)) }"
        case .string(.some(.uri)): return "PlankURI"
        case .string(.some(.dateTime)): return "PlankDate"
        case .string(.some), .string(.none): return "string"
        case .enumT(.string): return "" // TODO: JS: Not supported yet
        case .oneOf(types:_):
            fatalError("Nested oneOf types are unsupported at this time. Please file an issue if you require this. \(aSchema)")
        }
    }

    func renderAdtTypeRoots() -> [JSIR.Root] {
        return self.properties.flatMap { (param, prop) -> [JSIR.Root] in
            switch prop.schema {
            case .oneOf(types: let possibleTypes):
                return [renderAdtTypeRoot(property: param, schemas: possibleTypes)]
            case .array(itemType: .some(let itemType)):
                switch itemType {
                case .oneOf(types: let possibleTypes):
                    return [renderAdtTypeRoot(property: param, schemas: possibleTypes)]
                default: return []
                }
            case .map(valueType: .some(let additionalProperties)):
                switch additionalProperties {
                case .oneOf(types: let possibleTypes):
                    return [renderAdtTypeRoot(property: param, schemas: possibleTypes)]
                default: return []
                }
            default: return []
            }
        }
    }

    func renderAdtTypeRoot(property: String, schemas: [Schema]) -> JSIR.Root {
        let types = schemas.map { (schema) -> String in
            return JSModelRenderer.adtCaseTypeName(schema)
        }.joined(separator: " | ")

        // Just return it as a string for now
        return JSIR.Root.macro("export type \(JSModelRenderer.adtVariantTypeName(className: className, property: property)) = \(types);")
    }
}
