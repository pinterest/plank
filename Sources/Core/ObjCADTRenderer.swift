//
//  ObjectiveCADTRenderer.swift
//  plank
//
//  Created by Rahul Malik on 2/17/17.
//
//

import Foundation

extension ObjCModelRenderer {
    func adtRootsForSchema(property: String, schemas: [SchemaObjectProperty]) -> [ObjCIR.Root] {
        let adtName = "\(rootSchema.name)_\(property)"

        let enumOptions: [EnumValue<Int>] = schemas.enumerated().map { idx, schemaProp in
            let name = ObjCADTRenderer.objectName(schemaProp.schema)
            // Offset enum indexes by 1 to avoid matching the uninitialized case (i.e. enum property == 0)
            return EnumValue<Int>(defaultValue: idx + 1, description: "\(name)")
        }

        let internalTypeProp = ("internal_type", SchemaObjectProperty(schema: .enumT(.integer(enumOptions)), nullability: .nullable))

        let props = [internalTypeProp] + schemas.enumerated().map { ("value\($0)", $1) }

        let properties = props.reduce([String: SchemaObjectProperty](), { (acc: [String: SchemaObjectProperty], type: (String, SchemaObjectProperty)) -> [String: SchemaObjectProperty] in
            var mutableDict = acc
            mutableDict[type.0] = type.1
            return mutableDict
        })

        let root = SchemaObjectRoot(name: adtName,
                                    properties: properties,
                                    extends: nil,
                                    algebraicTypeIdentifier: nil)
        return ObjCADTRenderer(rootSchema: root,
                               params: params,
                               dataTypes: schemas).renderRoots()
    }
}

struct ObjCADTRenderer: ObjCFileRenderer {
    var rootSchema: SchemaObjectRoot

    let params: GenerationParameters
    let dataTypes: [SchemaObjectProperty]

    public static func objectName(_ aSchema: Schema) -> String {
        switch aSchema {
        case let .object(objectRoot):
            // Intentionally drop prefix
            return objectRoot.className(with: [:])
        case let .reference(with: ref):
            return ref.force().map(objectName) ?? {
                assert(false, "TODO: Forward optional across methods")
                return ""
            }()
        case .float: return "Float"
        case .integer: return "Integer"
        case .enumT(.integer): return "IntegerEnum" // TODO: Allow custom names
        case .boolean: return "Boolean"
        case .array(itemType: _): return "Array"
        case .set(itemType: _): return "Set"
        case .map(valueType: _): return "Dictionary"
        case .string(.some(.uri)): return "URL"
        case .string(.some(.dateTime)): return "Date"
        case .string(.some), .string(.none): return "String"
        case .enumT(.string): return "StringEnum" // TODO: Allow custom names
        case .oneOf(types: _):
            fatalError("Nested oneOf types are unsupported at this time. Please file an issue if you require this. \(aSchema)")
        }
    }

    var internalTypeEnumName: String {
        return className + "InternalType"
    }

    func renderInternalTypeEnum() -> ObjCIR.Root {
        let enumOptions: [EnumValue<Int>] = dataTypes.enumerated().map { idx, prop in
            let name = ObjCADTRenderer.objectName(prop.schema)
            // Offset enum indexes by 1 to avoid matching the
            return EnumValue<Int>(defaultValue: idx + 1, description: "\(name)")
        }
        return ObjCIR.Root.enumDecl(name: internalTypeEnumName,
                                    values: EnumType.integer(enumOptions))
    }

    func renderInternalEnumTypeCase(name: String) -> String {
        return className + "InternalType" + name
    }

    private func renderArgName(schema: Schema) -> (String, String) {
        let name = ObjCADTRenderer.objectName(schema)
        let arg = name.snakeCaseToPropertyName()
        return (name, arg)
    }

    func renderClassInitializers() -> [ObjCIR.Method] {
        return dataTypes.enumerated().map { index, prop in
            let (name, arg) = renderArgName(schema: prop.schema)
            return ObjCIR.method("+ (instancetype)objectWith\(name):(\(self.typeFromSchema(name, prop)))\(arg)") { [
                "\(self.className) *obj = [[\(self.className) alloc] init];",
                "obj.value\(index) = \(arg);",
                "obj.internalType = \(renderInternalEnumTypeCase(name: name));",
                "return obj;",
            ] }
        }
    }

    func renderDictionaryObjectRepresentation() -> ObjCIR.Method {
        return ObjCIR.method("- (id)dictionaryObjectRepresentation") {
            [
                ObjCIR.switchStmt("self.internalType") {
                    self.dataTypes.enumerated().map { (index, schemaObj) -> ObjCIR.SwitchCase in
                        ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schemaObj.schema)) { [
                            ObjCIR.scope { [
                                "NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];",
                                self.renderAddToDictionaryStatement(.ivar("value\(index)"),
                                                                    schemaObj.schema,
                                                                    "resultDict"),
                                "return resultDict[@\"value\(index)\"];",
                            ] },
                        ] }
                    }
                },
            ]
        }
    }

    func renderMatchFunction() -> ObjCIR.Method {
        let signatureComponents = dataTypes.enumerated().map { (index, prop) -> String in
            let (name, arg) = renderArgName(schema: prop.schema)
            return "\(index == 0 ? "match" : "or")\(name):(nullable PLANK_NOESCAPE void (^)(\(self.typeFromSchema(name, prop)) \(arg)))\(arg)MatchHandler"
        }

        return ObjCIR.method("- (void)\(signatureComponents.joined(separator: " "))") { [
            ObjCIR.switchStmt("self.internalType") {
                self.dataTypes.enumerated().map { (index, prop) -> ObjCIR.SwitchCase in
                    let (_, arg) = renderArgName(schema: prop.schema)
                    return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(prop.schema)) { [
                        ObjCIR.ifStmt("\(arg)MatchHandler != NULL") { [
                            ObjCIR.stmt("\(arg)MatchHandler(self.value\(index))"),
                        ] },
                    ] }
                }
            },
        ] }
    }

    func renderRoots() -> [ObjCIR.Root] {
        return renderClass(name: className)
    }

    func renderClass(name: String) -> [ObjCIR.Root] {
        let internalTypeEnum = renderInternalTypeEnum()
        let internalTypeProp: SimpleProperty = (
            "internal_type",
            typeFromSchema("internal_type", (.enumT(.integer([])) as Schema).nonnullProperty()),
            SchemaObjectProperty(schema: .enumT(.integer([]))),
            .readwrite
        )

        let protocols: [String: [ObjCIR.Method]] = [
            "NSSecureCoding": [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }],
        ]

        let props: [SimpleProperty] = [internalTypeProp] + dataTypes.enumerated()
            .map { idx, prop in ("value\(idx)", prop) }
            .map { param, prop in (param, typeFromSchema(param, prop), prop, .readwrite) }

        return [
            ObjCIR.Root.macro("NS_ASSUME_NONNULL_BEGIN"),
            internalTypeEnum,
            ObjCIR.Root.category(className: self.className,
                                 categoryName: nil,
                                 methods: [],
                                 properties: props),
            ObjCIR.Root.classDecl(name: name,
                                  extends: nil,
                                  methods:
                                  self.renderClassInitializers().map { (.publicM, $0) } +
                                      [
                                          (.publicM, self.renderMatchFunction()),
                                          (.privateM, self.renderIsEqual()),
                                          (.publicM, self.renderIsEqualToClass()),
                                          (.privateM, self.renderHash()),
                                          (.publicM, self.renderDictionaryObjectRepresentation()),
                                      ],
                                  properties: [],
                                  protocols: protocols),
            ObjCIR.Root.macro("NS_ASSUME_NONNULL_END"),
        ]
    }
}
