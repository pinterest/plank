//
//  ObjCFileRenderer.swift
//  plank
//
//  Created by Rahul Malik on 2/28/17.
//
//

import Foundation

protocol ObjCFileRenderer {
    var rootSchema: SchemaObjectRoot { get }
    var params: GenerationParameters { get }

    func renderRoots() -> [ObjCIR.Root]
}

extension ObjCFileRenderer {
    // MARK: Properties

    var className: String {
        return self.rootSchema.className(with: self.params)
    }

    var builderClassName: String {
        return "\(self.className)Builder"
    }

    var parentDescriptor: Schema? {
        return self.rootSchema.extends.flatMap { $0() }
    }

    var properties: [(Parameter, Schema)] {
        return self.rootSchema.properties.map { $0 }
    }

    var isBaseClass: Bool {
        return rootSchema.extends == nil
    }

    fileprivate func referencedClassNames(schema: Schema) -> [String] {
        switch schema {
        case .Reference(with: let fn):
            switch fn() {
            case .some(.Object(let schemaRoot)):
                return [schemaRoot.className(with: self.params)]
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        case .Object(let schemaRoot):
            return [schemaRoot.className(with: self.params)]
        case .Map(valueType: .some(let valueType)):
            return referencedClassNames(schema: valueType)
        case .Array(itemType: .some(let itemType)):
            return referencedClassNames(schema: itemType)
        case .OneOf(types: let itemTypes):
            return itemTypes.flatMap(referencedClassNames)
        default:
            return []
        }
    }

    func renderReferencedClasses() -> Set<String> {
        return Set(rootSchema.properties.values.flatMap(referencedClassNames))
    }

    func objcClassFromSchema(_ param: String, _ schema: Schema) -> String {
        switch schema {
        case .Array(itemType: .none):
            return "NSArray *"
        case .Array(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            // Objective-C primitive types are represented as NSNumber
            return "NSArray<NSNumber /* \(itemType.debugDescription) */ *> *"
        case .Array(itemType: .some(let itemType)):
            return "NSArray<\(objcClassFromSchema(param, itemType))> *"
        case .Map(valueType: .none):
            return "NSDictionary *"
        case .Map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "NSDictionary<NSString *, NSNumber /* \(valueType.debugDescription) */ *> *"
        case .Map(valueType: .some(let valueType)):
            return "NSDictionary<NSString *, \(objcClassFromSchema(param, valueType))> *"
        case .String(format: .none),
             .String(format: .some(.Email)),
             .String(format: .some(.Hostname)),
             .String(format: .some(.Ipv4)),
             .String(format: .some(.Ipv6)):
            return "NSString *"
        case .String(format: .some(.DateTime)):
            return "NSDate *"
        case .String(format: .some(.Uri)):
            return "NSURL *"
        case .Integer:
            return "NSInteger"
        case .Float:
            return "double"
        case .Boolean:
            return "BOOL"
        case .Enum(_):
            return enumTypeName(propertyName: param, className: className)
        case .Object(let objSchemaRoot):
            return "\(objSchemaRoot.className(with: params)) *"
        case .Reference(with: let fn):
            switch fn() {
            case .some(.Object(let schemaRoot)):
                return objcClassFromSchema(param, .Object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .OneOf(types:_):
            // TODO: Unify logic that creates ADT name since this is currently duplicated
            return "\(className)\(param.snakeCaseToCamelCase()) *"
        }
    }
}
