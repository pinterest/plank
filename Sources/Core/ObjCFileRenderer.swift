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

    fileprivate func referencedClassNames(schema: Schema) -> [String] {
        switch schema {
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return [schemaRoot.className(with: self.params)]
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

    func objcClassFromSchema(_ param: String, _ schema: Schema) -> String {
        switch schema {
        case .array(itemType: .none):
            return "NSArray *"
        case .array(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            // Objective-C primitive types are represented as NSNumber
            return "NSArray<NSNumber /* \(itemType.debugDescription) */ *> *"
        case .array(itemType: .some(let itemType)):
            return "NSArray<\(objcClassFromSchema(param, itemType))> *"
        case .set(itemType: .none):
            return "NSSet *"
        case .set(itemType: .some(let itemType)) where itemType.isObjCPrimitiveType:
            return "NSSet<NSNumber /*> \(itemType.debugDescription) */ *> *"
        case .set(itemType: .some(let itemType)):
            return "NSSet<\(objcClassFromSchema(param, itemType))> *"
        case .map(valueType: .none):
            return "NSDictionary *"
        case .map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType:
            return "NSDictionary<NSString *, NSNumber /* \(valueType.debugDescription) */ *> *"
        case .map(valueType: .some(let valueType)):
            return "NSDictionary<NSString *, \(objcClassFromSchema(param, valueType))> *"
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
                return objcClassFromSchema(param, .object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case .oneOf(types:_):
            return "\(className)\(param.snakeCaseToCamelCase()) *"
        }
    }
}
