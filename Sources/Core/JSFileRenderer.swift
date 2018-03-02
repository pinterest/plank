//
//  JSFileRenderer.swift
//  plank
//
//  Created by Michael Schneider
//
//

import Foundation

protocol JSFileRenderer {
    var rootSchema: SchemaObjectRoot { get }
    var params: GenerationParameters { get }

    func renderRoots() -> [JSIR.Root]
}

extension JSFileRenderer {

    var className: String {
        return self.rootSchema.className(with: self.params)
    }

    var typeName: String {
        return self.rootSchema.typeName(with: self.params)
    }

    var parentDescriptor: Schema? {
        return self.rootSchema.extends.flatMap { $0.force() }
    }

    var properties: [(Parameter, SchemaObjectProperty)] {
        return self.rootSchema.properties.map { $0 }.sorted(by: { (obj1, obj2) -> Bool in
            return obj1.0 < obj2.0
        })
    }

    var isBaseClass: Bool {
        return rootSchema.extends == nil
    }

    func referencedClassNames(schema: Schema) -> [String] {
        switch schema {
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return ["\(schemaRoot.typeName(with: self.params))"]
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        case .object(let schemaRoot):
            return [schemaRoot.className(with: self.params)]
        case .map(valueType: .some(let valueType)):
            return referencedClassNames(schema: valueType)
        case .array(itemType: .some(let itemType)), .set(itemType: .some(let itemType)):
            return referencedClassNames(schema: itemType)
        case .oneOf(types: let itemTypes):
            return itemTypes.flatMap(referencedClassNames)
        default:
            return []
        }
    }

    func renderReferencedClasses() -> Set<String> {
        return Set(rootSchema.properties.values.map { $0.schema }.flatMap(referencedClassNames))
    }

    func flowTypeName(_ param: String, _ schema: Schema) -> String {
        switch schema {
        case .array(itemType: .none):
            return "Array<*>"
        case .array(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            // JS primitive types are represented as number
            return "Array<number /* \(itemType.debugDescription) */>"
        case .array(itemType: .some(let itemType)):
            return "Array<\(flowTypeName(param, itemType))>"
        case .set(itemType: .none):
            return "Array<*>"
        case .set(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            return "Array<number /* \(itemType.debugDescription)> */>"
        case .set(itemType: .some(let itemType)):
            return "Array<\(flowTypeName(param, itemType))>"
        case .map(valueType: .none):
            return "{}"
        case .map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "{ +[string]: number } /* \(valueType.debugDescription) */"
        case .map(valueType: .some(let valueType)):
            return "{ +[string]: \(flowTypeName(param, valueType)) }"
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return "string"
        case .string(format: .some(.dateTime)):
            return "PlankDate"
        case .string(format: .some(.uri)):
            return "PlankURI"
        case .integer:
            return "number"
        case .float:
            return "number"
        case .boolean:
            return "boolean"
        case .enumT:
            return JSModelRenderer.enumTypeName(className: className, propertyName: param)
        case .object(let objSchemaRoot):
            return "\(objSchemaRoot.typeName(with: params))"
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return flowTypeName(param, .object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types:_):
            return JSModelRenderer.adtVariantTypeName(className: className, property: param)
        }
    }
}
