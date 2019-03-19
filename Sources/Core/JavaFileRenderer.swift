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
        return "\(className)Model"
    }

    func builderInterfaceName() -> String {
        return "\(className)ModelBuilder"
    }

    func interfaceName(_ schema: Schema?) -> String? {
        switch schema {
        case let .some(.object(root)):
            return JavaModelRenderer(rootSchema: root, params: params).interfaceName()
        case let .some(.reference(with: ref)):
            return resolveClassName(ref.force())
        default:
            return nil
        }
    }

    func builderInterfaceName(_ schema: Schema?) -> String? {
        switch schema {
        case let .some(.object(root)):
            return JavaModelRenderer(rootSchema: root, params: params).builderInterfaceName()
        case let .some(.reference(with: ref)):
            return resolveClassName(ref.force())
        default:
            return nil
        }
    }

    func typeFromSchema(_ param: String, _ schema: SchemaObjectProperty) -> String {
        switch schema.nullability {
        case .some(.nonnull):
            return "@NonNull \(unwrappedTypeFromSchema(param, schema.schema))"
        case .some(.nullable), .none:
            return "@Nullable \(unwrappedTypeFromSchema(param, schema.schema))"
        }
    }

    fileprivate func unwrappedTypeFromSchema(_ param: String, _ schema: Schema) -> String {
        switch schema {
        case .array(itemType: .none):
            return "List<Object>"
        case let .array(itemType: .some(itemType)):
            return "List<\(unwrappedTypeFromSchema(param, itemType))>"
        case .set(itemType: .none):
            return "Set<Object>"
        case let .set(itemType: .some(itemType)):
            return "Set<\(unwrappedTypeFromSchema(param, itemType))>"
        case .map(valueType: .none):
            return "Map<String, Object>"
        case let .map(valueType: .some(valueType)):
            return "Map<String, \(unwrappedTypeFromSchema(param, valueType))>"
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
        case .enumT:
            return enumTypeName(propertyName: param, className: className)
        case let .object(objSchemaRoot):
            return "\(objSchemaRoot.className(with: params))"
        case let .reference(with: ref):
            switch ref.force() {
            case let .some(.object(schemaRoot)):
                return unwrappedTypeFromSchema(param, .object(schemaRoot) as Schema)
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types: _):
            return "\(className)\(Languages.java.snakeCaseToCamelCase(param))"
        }
    }
}
