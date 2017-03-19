//
//  ObjectiveCADTRenderer.swift
//  plank
//
//  Created by Rahul Malik on 2/17/17.
//
//

import Foundation

extension ObjCModelRenderer {
    func adtRootsForSchema(property: String, schemas: [Schema]) -> [ObjCIR.Root] {
        let adtName = "\(self.rootSchema.name)_\(property)"

        let enumOptions: [EnumValue<Int>] = schemas.enumerated().map { (idx, schema) in
            let name = ObjCADTRenderer.objectName(schema)
            // Offset enum indexes by 1 to avoid matching the uninitialized case (i.e. enum property == 0)
            return EnumValue<Int>(defaultValue: idx + 1, description: "\(name)")
        }

        let internalTypeProp: (String, Schema) = ("internal_type", .Enum(.Integer(enumOptions)))

        let props  = [internalTypeProp] + schemas.enumerated().map { ("value\($0)", $1) }
        let properties = props.reduce([String: Schema](), { (d: [String: Schema], t: (String, Schema)) -> [String: Schema] in
            var mutableDict = d
            mutableDict[t.0] = t.1
            return mutableDict
        })

        let root = SchemaObjectRoot(name: adtName,
                                    properties: properties,
                                    extends: nil,
                                    algebraicTypeIdentifier: nil)
        return ObjCADTRenderer.init(rootSchema: root,
                                        params: self.params,
                                        dataTypes: schemas).renderRoots()
    }
}

struct ObjCADTRenderer: ObjCFileRenderer {
    var rootSchema: SchemaObjectRoot

    let params: GenerationParameters
    let dataTypes: [Schema]

    public static func objectName(_ aSchema: Schema) -> String {
        switch aSchema {
        case .Object(let objectRoot):
            // Intentionally drop prefix
            return objectRoot.className(with: [:])
        case .Reference(with: let ref):
            return ref.force().map(objectName) ?? {
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
            fatalError("Nested oneOf types are unsupported at this time. Please file an issue if you require this. \(aSchema)")
        }
    }

    var internalTypeEnumName: String {
        return self.className + "InternalType"
    }

    func renderInternalTypeEnum() -> ObjCIR.Root {
        let enumOptions: [EnumValue<Int>] = self.dataTypes.enumerated().map { (idx, schema) in
            let name = ObjCADTRenderer.objectName(schema)
            // Offset enum indexes by 1 to avoid matching the
            return EnumValue<Int>(defaultValue: idx + 1, description: "\(name)")
        }
        return ObjCIR.Root.Enum(name: self.internalTypeEnumName,
                                values: EnumType.Integer(enumOptions))
    }

    func renderInternalEnumTypeCase(name: String) -> String {
        return self.className + "InternalType" + name
    }

    func renderClassInitializers() -> [ObjCIR.Method] {
        return self.dataTypes.enumerated().map { (index, schema) in
            let name = ObjCADTRenderer.objectName(schema)
            let arg = String(name.characters.prefix(1)).lowercased() + String(name.characters.dropFirst())

            return ObjCIR.method("+ (instancetype)objectWith\(name):(\(self.objcClassFromSchema(name, schema)))\(arg)") {
                [
                    "\(self.className) *obj = [[\(self.className) alloc] init];",
                    "obj.value\(index) = \(arg);",
                    "obj.internalType = \(renderInternalEnumTypeCase(name: name));",
                    "return obj;"
                ]
            }
        }
    }

    func renderMatchFunction() -> ObjCIR.Method {
        let signatureComponents  = self.dataTypes.enumerated().map { (index, schema) -> String in
            let name = ObjCADTRenderer.objectName(schema)
            let arg = String(name.characters.prefix(1)).lowercased() + String(name.characters.dropFirst())
            return "\(index == 0 ? "match" : "or")\(name):(nullable PLANK_NOESCAPE void (^)(\(self.objcClassFromSchema(name, schema)) \(arg)))\(arg)MatchHandler"
        }

        return ObjCIR.method("- (void)\(signatureComponents.joined(separator: " "))") {[
            ObjCIR.switchStmt("self.internalType") {
                self.dataTypes.enumerated().map { (index, schema) -> ObjCIR.SwitchCase in
                    let name = ObjCADTRenderer.objectName(schema)
                    let arg = String(name.characters.prefix(1)).lowercased() + String(name.characters.dropFirst())
                    return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                        ObjCIR.ifStmt("\(arg)MatchHandler != NULL") {[
                            ObjCIR.stmt("\(arg)MatchHandler(self.value\(index))")
                        ]}
                    ]}
                }
            }
        ]}
    }

    func renderRoots() -> [ObjCIR.Root] {
        return renderClass(name: self.className)
    }
    func renderClass(name: String) -> [ObjCIR.Root] {
        let internalTypeEnum = self.renderInternalTypeEnum()
        let internalTypeProp: SimpleProperty = ("internal_type", objcClassFromSchema("internal_type", .Enum(.Integer([]))), .Enum(.Integer([])), .ReadWrite)

        let protocols: [String : [ObjCIR.Method]] = [
            "NSSecureCoding": [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }]
        ]

        let props: [SimpleProperty] = [internalTypeProp] + self.dataTypes.enumerated()
            .map { idx, schema in ("value\(idx)", schema) }
            .map { param, schema in (param, objcClassFromSchema(param, schema), schema, .ReadWrite) }

        return [
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_BEGIN"),
            internalTypeEnum,
            ObjCIR.Root.Category(className: self.className,
                                 categoryName: nil,
                                 methods: [],
                                 properties: props),
            ObjCIR.Root.Class(name: name,
                             extends: nil,
                             methods:
                               self.renderClassInitializers().map { (.Public, $0) } +
                               [
                                (.Public, self.renderMatchFunction()),
                                (.Private, self.renderIsEqual()),
                                (.Public, self.renderIsEqualToClass()),
                                (.Private, self.renderHash())
                                ],
                             properties: [],
                             protocols: protocols),
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_END")
        ]
    }
}
