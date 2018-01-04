//
//  JavaFileRenderer.swift
//  Core
//
//  Created by Rahul Malik on 1/12/18.
//

import Foundation

protocol JavaFileRenderer: FileRenderer {}

extension JavaFileRenderer {
    func interfaceName() -> String {
        return "\(self.className)Model"
    }

    func builderInterfaceName() -> String {
        return "\(self.className)ModelBuilder"
    }

    func interfaceName(_ schema: Schema?) -> String? {
        switch schema {
        case .some(.object(let root)):
            return JavaModelRenderer(rootSchema: root, params: self.params).interfaceName()
        case .some(.reference(with: let ref)):
            return resolveClassName(ref.force())
        default:
            return nil
        }
    }

    func builderInterfaceName(_ schema: Schema?) -> String? {
        switch schema {
        case .some(.object(let root)):
            return JavaModelRenderer(rootSchema: root, params: self.params).builderInterfaceName()
        case .some(.reference(with: let ref)):
            return resolveClassName(ref.force())
        default:
            return nil
        }
    }

    func typeFromSchema(_ param: String, _ schema: SchemaObjectProperty) -> String {
        switch schema.nullability {
        case .some(.nonnull):
            return unwrappedTypeFromSchema(param, schema.schema)
        case .some(.nullable), .none:
            return "@Nullable \(unwrappedTypeFromSchema(param, schema.schema))"
        }
    }
    fileprivate func unwrappedTypeFromSchema(_ param: String, _ schema: Schema) -> String {
        switch schema {
        case .array(itemType: .none):
            return "List<Object>"
        case .array(itemType: .some(let itemType)):
            return "List<\(typeFromSchema(param, itemType.nonnullProperty()))>"
        case .set(itemType: .none):
            return "Set<Object>"
        case .set(itemType: .some(let itemType)):
            return "Set<\(typeFromSchema(param, itemType.nonnullProperty()))>"
        case .map(valueType: .none):
            return "Map<String, Object>"
        case .map(valueType: .some(let valueType)):
            return "Map<String, \(typeFromSchema(param, valueType.nonnullProperty()))>"
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)),
             .string(format: .some(.uri)):
            return "String"
        case .string(format: .some(.dateTime)):
            return "Date"
        case .integer:
            return "Integer"
        case .float:
            return "Double"
        case .boolean:
            return "Boolean"
        case .enumT(let enumObj):
            let enumName = enumTypeName(propertyName: param, className: className)
            switch enumObj {
            case .integer(_):
                return "@\(enumName) int"
            case .string(_, defaultValue: _):
                return "@\(enumName) String"
            }
        case .object(let objSchemaRoot):
            return "\(objSchemaRoot.className(with: params))"
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return typeFromSchema(param, (.object(schemaRoot) as Schema).nonnullProperty())
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types:_):
            return "\(className)\(param.snakeCaseToCamelCase())"
        }
    }
}
