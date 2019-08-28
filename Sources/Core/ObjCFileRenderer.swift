//
//  ObjCFileRenderer.swift
//  plank
//
//  Created by Rahul Malik on 2/28/17.
//
//

import Foundation

protocol ObjCFileRenderer: FileRenderer {}

extension ObjCFileRenderer {
    var builderClassName: String {
        return "\(className)Builder"
    }

    func typeFromSchema(_ param: String, _ schema: SchemaObjectProperty) -> String {
        switch schema.schema {
        case .array(itemType: .none):
            return "NSArray *"
        case let .array(itemType: .some(itemType)) where itemType.isPrimitiveType:
            // Objective-C primitive types are represented as NSNumber
            return "NSArray<NSNumber /* \(itemType.debugDescription) */ *> *"
        case let .array(itemType: .some(itemType)):
            return "NSArray<\(typeFromSchema(param, itemType.nonnullProperty()))> *"
        case .set(itemType: .none):
            return "NSSet *"
        case let .set(itemType: .some(itemType)) where itemType.isPrimitiveType:
            return "NSSet<NSNumber /*> \(itemType.debugDescription) */ *> *"
        case let .set(itemType: .some(itemType)):
            return "NSSet<\(typeFromSchema(param, itemType.nonnullProperty()))> *"
        case .map(valueType: .none):
            return "NSDictionary *"
        case let .map(valueType: .some(valueType)) where valueType.isPrimitiveType:
            return "NSDictionary<NSString *, NSNumber /* \(valueType.debugDescription) */ *> *"
        case let .map(valueType: .some(valueType)):
            return "NSDictionary<NSString *, \(typeFromSchema(param, valueType.nonnullProperty()))> *"
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return "NSString *"
        case .string(format: .some(.dateTime)):
            return "NSDate *"
        case .string(format: .some(.uri)):
            return "NSURL *"
        case .integer:
            return "NSInteger"
        case .float:
            return "double"
        case .boolean:
            return "BOOL"
        case .enumT:
            return enumTypeName(propertyName: param, className: className)
        case let .object(objSchemaRoot):
            return "\(objSchemaRoot.className(with: params)) *"
        case let .reference(with: ref):
            switch ref.force() {
            case let .some(.object(schemaRoot)):
                return typeFromSchema(param, (.object(schemaRoot) as Schema).nonnullProperty())
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types: _):
            return "\(className)\(Languages.objectiveC.snakeCaseToCamelCase(param)) *"
        }
    }
}
