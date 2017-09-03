//
//  KotlinFileRenderer.swift
//  Core
//
//  Created by Levi McCallum on 9/3/17.
//

import Foundation

protocol KotlinFileRenderer {
    var rootSchema: SchemaObjectRoot { get }
    var params: GenerationParameters { get }
    
    func renderRoots() -> [KotlinIR.Root]
}

extension KotlinFileRenderer {
    var className: String {
        return rootSchema.className(with: params)
    }
    
    var properties: [(Parameter, SchemaObjectProperty)] {
        return rootSchema.properties.map { $0 }
    }
    
    func kotlinType(schema: Schema, param: String) -> String {
        switch schema {
        case .array(itemType: .none):
            return "Array<Any>"
        case .array(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            // Primitive types are represented as NSNumber
            return "IntArray /* \(itemType.debugDescription) */"
        case .array(itemType: .some(let itemType)):
            return "Array<\(swiftType(schema: itemType, param: param))>"
        case .map(valueType: .none):
            return "HashMap<String, Any>"
        case .map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "HashMap<String, Int> /* \(valueType.debugDescription) */"
        case .map(valueType: .some(let valueType)):
            return "HashMap<String, \(swiftType(schema: valueType, param: param))>"
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return "String"
        case .string(format: .some(.dateTime)):
            return "Date"
        case .string(format: .some(.uri)):
            // TODO: http://docs.oracle.com/javase/8/docs/api/java/net/URL.html
            return "URL"
        case .integer:
            return "Int"
        case .float:
            return "Double"
        case .boolean:
            return "Bool"
        case .enumT:
            // TODO: Kotlin When
            return enumTypeName(propertyName: param, className: className)
        case .object(let objSchemaRoot):
            return "\(objSchemaRoot.className(with: params))"
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return kotlinType(schema: .object(schemaRoot), param: param)
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types:_):
            return "\(className)\(param.snakeCaseToCamelCase())"
        }
    }
}
