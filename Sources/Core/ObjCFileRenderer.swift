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
        return "\(self.className)Builder"
    }

    func typeFromSchema(_ param: String, _ schema: SchemaObjectProperty) -> String {
        switch schema.schema {
        case .array(itemType: .none):
            return "NSArray *"
        case .array(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            // Objective-C primitive types are represented as NSNumber
            return "NSArray<NSNumber /* \(itemType.debugDescription) */ *> *"
        case .array(itemType: .some(let itemType)):
            return "NSArray<\(typeFromSchema(param, itemType.nonnullProperty()))> *"
        case .set(itemType: .none):
            return "NSSet *"
        case .set(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            return "NSSet<NSNumber /*> \(itemType.debugDescription) */ *> *"
        case .set(itemType: .some(let itemType)):
            return "NSSet<\(typeFromSchema(param, itemType.nonnullProperty()))> *"
        case .map(valueType: .none):
            return "NSDictionary *"
        case .map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "NSDictionary<NSString *, NSNumber /* \(valueType.debugDescription) */ *> *"
        case .map(valueType: .some(let valueType)):
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
        case .object(let objSchemaRoot):
            return "\(objSchemaRoot.className(with: params)) *"
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return typeFromSchema(param, (.object(schemaRoot) as Schema).nonnullProperty())
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types:_):
            return "\(className)\(param.snakeCaseToCamelCase()) *"
        }
    }
}
