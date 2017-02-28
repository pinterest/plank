//
//  ObjectiveCADTExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/17/17.
//
//

import Foundation

struct ObjCADTRootRenderer {
    let params: GenerationParameters
    let className: String
    let dataTypes: [Schema]

    var objcClassFromSchema: (String, Schema) -> String {
        return objcClassFromSchemaFn(self.className, self.params)
    }

    private func objectName(_ aSchema: Schema) -> String {
        switch aSchema {
        case .Object(let objectRoot):
            // Intentionally drop prefix
            return objectRoot.className(with: [:])
        case .Reference(with: let refFunc):
            return refFunc().map(objectName) ?? {
                assert(false, "TODO: Forward optional across methods")
                return ""
                }()
        case .Float: return "Float"
        case .Integer: return "Integer"
        case .Enum(.Integer(_)): return "IntegerEnum"  // TODO: Allow custom names
        case .Boolean: return "Boolean"
        case .Array(itemType: _): return "Array"
        case .Map(valueType: _): return "Dictionary"
        case .String(.some(.Uri)): return "URL"
        case .String(.some(.DateTime)): return "Date"
        case .String(.some(_)), .String(.none): return "String"
        case .Enum(.String(_)): return "StringEnum" // TODO: Allow custom names
        case .OneOf(types:_):
            fatalError("Nested oneOf types are unsupported at this time. Please file an issue if you require this.")
        }
    }

    var internalTypeEnumName: String {
        return self.className + "InternalType"
    }

    func renderInternalTypeEnum() -> ObjCIR.Root {
        let enumOptions: [EnumValue<Int>] = self.dataTypes.enumerated().map { (idx, schema) in
            let name = objectName(schema)
            return EnumValue<Int>(defaultValue: idx, description: "\(name)")
        }
        return ObjCIR.Root.Enum(name: self.internalTypeEnumName,
                                values: EnumType.Integer(enumOptions))
    }

    func renderClassInitializers() -> [ObjCIR.Method] {
        return self.dataTypes.enumerated().map { (index, schema) in
            let name = objectName(schema)
            let arg = String(name.characters.prefix(1)).lowercased() + String(name.characters.dropFirst())

            return ObjCIR.method("+ (instancetype)objectWith\(name):(\(self.objcClassFromSchema(name, schema)))\(arg)") {
                [
                    "\(self.className) *obj = [[\(self.className) alloc] init];",
                    "obj.value\(index) = \(arg);",
                    "obj.internalType = \(self.className + "InternalType" + name);",
                    "return obj;"
                ]
            }
        }
    }

    func renderClass(name: String) -> [ObjCIR.Root] {

        let props: [SimpleProperty] = self.dataTypes.enumerated()
            .map { idx, schema in ("value\(idx)", schema) }
            .map {  param, schema in (param, objcClassFromSchema(param, schema), schema, .ReadWrite) }

        return [self.renderInternalTypeEnum()] + [
            ObjCIR.Root.Category(className: self.className,
                                 categoryName: nil,
                                 methods: [],
                                 properties: props),
            ObjCIR.Root.Class(name: name,
                             extends: nil,
                             methods: self.renderClassInitializers().map { (.Public, $0)},
                             properties:[],
                             protocols:["NSCopying": [], "NSSecureCoding": []])
        ]
    }
}

extension ObjCRootsRenderer {
    func adtClassName(forProperty property: String) -> String {
        return self.className + property.snakeCaseToCamelCase()
    }

    func adtRootsForSchema(property: String, schemas: [Schema]) -> [ObjCIR.Root] {
        return ObjCADTRootRenderer(
            params: self.params,
            className: self.adtClassName(forProperty: property),
            dataTypes: schemas
        ).renderClass(name: self.adtClassName(forProperty: property))
    }
}
