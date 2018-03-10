//
//  JSFileRenderer.swift
//  plank
//
//  Created by Michael Schneider
//
//

import Foundation

protocol JSFileRenderer: FileRenderer {}

extension JSFileRenderer {
    func typeFromSchema(_ param: String, _ schema: SchemaObjectProperty) -> String {
        switch schema.schema {
        case .array(itemType: .none):
            return "Array<*>"
        case .array(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            // JS primitive types are represented as number
            return "Array<number /* \(itemType.debugDescription) */>"
        case .array(itemType: .some(let itemType)):
            return "Array<\(typeFromSchema(param, itemType.nonnullProperty()))>"
        case .set(itemType: .none):
            return "Array<*>"
        case .set(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            return "Array<number /* \(itemType.debugDescription)> */>"
        case .set(itemType: .some(let itemType)):
            return "Array<\(typeFromSchema(param, itemType.nonnullProperty()))>"
        case .map(valueType: .none):
            return "{}"
        case .map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "{ +[string]: number } /* \(valueType.debugDescription) */"
        case .map(valueType: .some(let valueType)):
            return "{ +[string]: \(typeFromSchema(param, valueType.nonnullProperty())) }"
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
                return typeFromSchema(param, (.object(schemaRoot) as Schema).nonnullProperty())
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types:_):
            return JSModelRenderer.adtVariantTypeName(className: className, property: param)
        }
    }
}
