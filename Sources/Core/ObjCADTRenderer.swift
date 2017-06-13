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

        let internalTypeProp: (String, Schema) = ("internal_type", .enumT(.integer(enumOptions)))

        let props  = [internalTypeProp] + schemas.enumerated().map { ("value\($0)", $1) }
        let properties = props.reduce([String: Schema](), { (acc: [String: Schema], type: (String, Schema)) -> [String: Schema] in
            var mutableDict = acc
            mutableDict[type.0] = type.1
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
        case .object(let objectRoot):
            // Intentionally drop prefix
            return objectRoot.className(with: [:])
        case .reference(with: let ref):
            return ref.force().map(objectName) ?? {
                assert(false, "TODO: Forward optional across methods")
                return ""
                }()
        case .float: return "Float"
        case .integer: return "Integer"
        case .enumT(.integer): return "IntegerEnum"  // TODO: Allow custom names
        case .boolean: return "Boolean"
        case .array(itemType: _): return "Array"
        case .map(valueType: _): return "Dictionary"
        case .string(.some(.uri)): return "URL"
        case .string(.some(.dateTime)): return "Date"
        case .string(.some), .string(.none): return "String"
        case .enumT(.string): return "StringEnum" // TODO: Allow custom names
        case .oneOf(types:_):
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
        return ObjCIR.Root.enumDecl(name: self.internalTypeEnumName,
                                    values: EnumType.integer(enumOptions))
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

    func renderDictionaryRepresentation() -> ObjCIR.Method {
            return ObjCIR.method("- (id)dictionaryRepresentation") {
                [
                    ObjCIR.switchStmt("self.internalType") {
                        self.dataTypes.enumerated().map { (index, schema) -> ObjCIR.SwitchCase in
                            switch(schema) {
                            case .object:
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [[NSDictionary alloc]initWithDictionary:[self.value\(index) dictionaryRepresentation]]")
                                    ]}
                            case .reference:
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [[NSDictionary alloc]initWithDictionary:[self.value\(index) dictionaryRepresentation]]")
                                    ]}
                            case .float:
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [NSNumber numberWithFloat:self.value\(index)]")
                                    ]}
                            case .integer:
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [NSNumber numberWithInteger:self.value\(index)]")
                                    ]}
                            case .enumT(.integer):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [NSNumber numberWithInteger:self.value\(index)]")
                                    ]}
                            case .boolean:
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [NSNumber numberWithBool:self.value\(index)]")
                                    ]}
                            case .array(itemType: _):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [[NSDictionary alloc]initWithDictionary:[self.value\(index) dictionaryRepresentation]]")
                                    ]}
                            case .map(valueType: _):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [[NSDictionary alloc]initWithDictionary:[self.value\(index) absoluteString] ]")
                                    ]}
                            case .string(.some(.uri)):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [self.value\(index) absoluteString]")
                                    ]}
                            case .string(.some(.dateTime)):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] reverseTransformedValue:self.value\(index)]")
                                    ]}
                            case .string(.some), .string(.none):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                ObjCIR.stmt("return self.value\(index)")
                                ]}
                            case .enumT(.string):
                                return ObjCIR.caseStmt(self.internalTypeEnumName + ObjCADTRenderer.objectName(schema)) {[
                                    ObjCIR.stmt("return "+enumToStringMethodName(propertyName: self.internalTypeEnumName, className: self.className))
                                    ]}
                            case .oneOf(types:_):
                                //error
                                fatalError("Nested oneOf types are unsupported at this time. Please file an issue if you require this. \(schema)")
                            }
                        }
                    }
                ]
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
        let internalTypeProp: SimpleProperty = ("internal_type", objcClassFromSchema("internal_type", .enumT(.integer([]))), .enumT(.integer([])), .readwrite)

        let protocols: [String : [ObjCIR.Method]] = [
            "NSSecureCoding": [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }]
        ]

        let props: [SimpleProperty] = [internalTypeProp] + self.dataTypes.enumerated()
            .map { idx, schema in ("value\(idx)", schema) }
            .map { param, schema in (param, objcClassFromSchema(param, schema), schema, .readwrite) }

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
                                    (.publicM, self.renderDictionaryRepresentation())
                                    ],
                                 properties: [],
                                 protocols: protocols),
            ObjCIR.Root.macro("NS_ASSUME_NONNULL_END")
        ]
    }
}
