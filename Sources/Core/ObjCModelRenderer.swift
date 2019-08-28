//
//  ObjCModelRenderer.swift
//  Plank
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

let rootNSObject = SchemaObjectRoot(name: "NSObject", properties: [:], extends: nil, algebraicTypeIdentifier: nil)

public struct ObjCModelRenderer: ObjCFileRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }

    var dirtyPropertyOptionName: String {
        return "\(className)DirtyProperties"
    }

    var booleanPropertiesStructName: String {
        return "\(className)BooleanProperties"
    }

    var dirtyPropertiesIVarName: String {
        return "\(Languages.objectiveC.snakeCaseToPropertyName(rootSchema.name))DirtyProperties"
    }

    var booleanPropertiesIVarName: String {
        return "\(Languages.objectiveC.snakeCaseToPropertyName(rootSchema.name))BooleanProperties"
    }

    // MARK: Model methods

    func renderClassName() -> ObjCIR.Method {
        return ObjCIR.method("+ (NSString *)className") {
            ["return \(self.className.objcLiteral());"]
        }
    }

    func renderPolymorphicTypeIdentifier() -> ObjCIR.Method {
        return ObjCIR.method("+ (NSString *)polymorphicTypeIdentifier") {
            ["return \(self.rootSchema.typeIdentifier.objcLiteral());"]
        }
    }

    func renderCopyWithBlock() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(\(builderClassName) *builder))block") {
            [
                "NSParameterAssert(block);",
                "\(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
                "block(builder);",
                "return [builder build];",
            ]
        }
    }

    func renderMergeWithModel() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)mergeWithModel:(\(className) *)modelObject") {
            ["return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];"]
        }
    }

    func renderMergeWithModelWithInitType() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)mergeWithModel:(\(className) *)modelObject initType:(PlankModelInitType)initType") {
            [
                "NSParameterAssert(modelObject);",
                "\(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
                "[builder mergeWithModel:modelObject];",
                "return [[\(self.className) alloc] initWithBuilder:builder initType:initType];",
            ]
        }
    }

    func renderStringEnumerationMethods() -> [ObjCIR.Method] {
        func renderToStringMethod(param: String, enumValues: [EnumValue<String>]) -> ObjCIR.Method {
            let enumTypeString = enumTypeName(propertyName: param, className: className)
            return ObjCIR.method("extern NSString * _Nonnull \(enumTypeString)ToString(\(enumTypeString) enumType)") { [
                ObjCIR.switchStmt("enumType") {
                    enumValues.map({ (val) -> ObjCIR.SwitchCase in
                        ObjCIR.caseStmt(val.objcOptionName(param: param, className: self.className)) {
                            ["return \(val.defaultValue.objcLiteral());"]
                        }
                    })
                },
            ] }
        }

        func renderFromStringMethod(param: String, enumValues: [EnumValue<String>], defaultValue: EnumValue<String>) -> ObjCIR.Method {
            let enumTypeString = enumTypeName(propertyName: param, className: className)

            return ObjCIR.method("extern \(enumTypeString) \(enumTypeString)FromString(NSString * _Nonnull str)") {
                enumValues.map { (val) -> String in
                    ObjCIR.ifStmt("[str isEqualToString:\(val.defaultValue.objcLiteral())]") {
                        [
                            "return \(val.objcOptionName(param: param, className: self.className));",
                        ]
                    }
                }
                    + ["return \(defaultValue.objcOptionName(param: param, className: self.className));"]
            }
        }

        return properties.flatMap { (param, prop) -> [ObjCIR.Method] in
            switch prop.schema {
            case let .enumT(.string(enumValues, defaultValue)):
                return [
                    renderToStringMethod(param: param, enumValues: enumValues),
                    renderFromStringMethod(param: param, enumValues: enumValues, defaultValue: defaultValue),
                ]
            default:
                return []
            }
        }
    }

    func renderIsSetMethods() -> [ObjCIR.Method] {
        return properties.map { param, _ in
            ObjCIR.method("- (BOOL)is\(Languages.objectiveC.snakeCaseToCamelCase(param))Set") { [
                "return _\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) == 1;",
            ] }
        }
    }

    func renderBooleanPropertyAccessorMethods() -> [ObjCIR.Method] {
        return properties.flatMap { (param, prop) -> [ObjCIR.Method] in
            switch prop.schema {
            case .boolean:
                return [ObjCIR.method("- (BOOL)\(Languages.objectiveC.snakeCaseToPropertyName(param))") { ["return _\(self.booleanPropertiesIVarName).\(booleanPropertyOption(propertyName: param, className: self.className));"] }]
            default:
                return []
            }
        }
    }

    func renderRoots() -> [ObjCIR.Root] {
        let booleanProperties = rootSchema.properties.filter { (arg) -> Bool in
            let (_, schema) = arg
            return schema.schema.isBoolean()
        }

        let booleanStructDeclaration = !booleanProperties.isEmpty ? [ObjCIR.Root.structDecl(name: self.booleanPropertiesStructName,
                                                                                            fields: booleanProperties.keys.map { "unsigned int \(booleanPropertyOption(propertyName: $0, className: self.className)):1;" })] : []

        let booleanIvarDeclaration: [SimpleProperty] = !booleanProperties.isEmpty ? [(self.booleanPropertiesIVarName, "struct \(self.booleanPropertiesStructName)",
                                                                                      SchemaObjectProperty(schema: .integer, nullability: nil),
                                                                                      .readwrite)] : []

        let enumProperties = properties.filter { (arg) -> Bool in
            let (_, schema) = arg
            switch schema.schema {
            case .enumT:
                return true
            default:
                return false
            }
        }

        let enumIVarDeclarations: [(Parameter, TypeName)] = enumProperties.compactMap { (arg) -> (Parameter, TypeName) in
            let (param, prop) = arg
            return (param, enumTypeName(propertyName: param, className: self.className))
        }

        let protocols: [String: [ObjCIR.Method]] = [
            "NSSecureCoding": [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }],
        ]

        let parentName = resolveClassName(parentDescriptor)

        func enumRoot(from prop: Schema, param: String) -> [ObjCIR.Root] {
            switch prop {
            case let .enumT(enumValues):
                return [ObjCIR.Root.enumDecl(name: enumTypeName(propertyName: param, className: self.className), values: enumValues)]
            case let .oneOf(types: possibleTypes):
                return possibleTypes.flatMap { enumRoot(from: $0, param: param) }
            case let .array(itemType: .some(itemType)):
                return enumRoot(from: itemType, param: param)
            case let .map(valueType: .some(additionalProperties)):
                return enumRoot(from: additionalProperties, param: param)
            default: return []
            }
        }

        let enumRoots = properties.flatMap { (param, prop) -> [ObjCIR.Root] in
            enumRoot(from: prop.schema, param: param)
        }

        // TODO: Synthesize oneOf ADT Classes and Class Extension
        // TODO: (rmalik): Clean this up, too much copy / paste here to support oneOf cases
        let adtRoots = properties.flatMap { (param, prop) -> [ObjCIR.Root] in
            switch prop.schema {
            case let .oneOf(types: possibleTypes):
                let objProps = possibleTypes.map { SchemaObjectProperty(schema: $0, nullability: $0.isPrimitiveType ? nil : .nullable) }
                return adtRootsForSchema(property: param, schemas: objProps)
            case let .array(itemType: .some(itemType)):
                switch itemType {
                case let .oneOf(types: possibleTypes):
                    let objProps = possibleTypes.map { SchemaObjectProperty(schema: $0, nullability: $0.isPrimitiveType ? nil : .nullable) }
                    return adtRootsForSchema(property: param, schemas: objProps)
                default: return []
                }
            case let .map(valueType: .some(additionalProperties)):
                switch additionalProperties {
                case let .oneOf(types: possibleTypes):
                    let objProps = possibleTypes.map { SchemaObjectProperty(schema: $0, nullability: $0.isPrimitiveType ? nil : .nullable) }
                    return adtRootsForSchema(property: param, schemas: objProps)
                default: return []
                }
            default: return []
            }
        }

        return [
            ObjCIR.Root.imports(
                classNames: Set(self.renderReferencedClasses().map {
                    // Objective-C types contain "*" if they are a pointer type
                    // This information is excessive for import statements so
                    // we're removing it here.
                    $0.replacingOccurrences(of: "*", with: "")
                }),
                myName: self.className,
                parentName: parentName
            ),
        ] + adtRoots + enumRoots + [
            ObjCIR.Root.structDecl(name: self.dirtyPropertyOptionName,
                                   fields: rootSchema.properties.keys
                                       .map { "unsigned int \(dirtyPropertyOption(propertyName: $0, className: self.className)):1;" }),
        ]
            + booleanStructDeclaration +
            [ObjCIR.Root.category(className: self.className,
                                  categoryName: nil,
                                  methods: [],
                                  properties: [(self.dirtyPropertiesIVarName, "struct \(self.dirtyPropertyOptionName)",
                                                SchemaObjectProperty(schema: .integer, nullability: nil),
                                                .readwrite)] + booleanIvarDeclaration,
                                  variables: enumIVarDeclarations),
             ObjCIR.Root.category(className: self.builderClassName,
                                  categoryName: nil,
                                  methods: [],
                                  properties: [(self.dirtyPropertiesIVarName, "struct \(self.dirtyPropertyOptionName)",
                                                SchemaObjectProperty(schema: .integer, nullability: nil),
                                                .readwrite)],
                                  variables: [])] + renderStringEnumerationMethods().map { ObjCIR.Root.function($0) } + [
                ObjCIR.Root.macro("NS_ASSUME_NONNULL_BEGIN"),
                                      ObjCIR.Root.classDecl(
                    name: self.className,
                                          extends: parentName,
                                          methods: [
                        (self.isBaseClass ? .publicM : .privateM, self.renderClassName()),
                                              (self.isBaseClass ? .publicM : .privateM, self.renderPolymorphicTypeIdentifier()),
                                              (self.isBaseClass ? .publicM : .privateM, self.renderModelObjectWithDictionary()),
                                              (.privateM, self.renderDesignatedInit()),
                                              (self.isBaseClass ? .publicM : .privateM, self.renderInitWithModelDictionary()),
                                              (.publicM, self.renderInitWithBuilder()),
                                              (self.isBaseClass ? .publicM : .privateM, self.renderInitWithBuilderWithInitType()),
                                              (.privateM, self.renderDebugDescription()),
                                              (.publicM, self.renderCopyWithBlock()),
                                              (.privateM, self.renderIsEqual()),
                                              (.publicM, self.renderIsEqualToClass(self.booleanPropertiesIVarName)),
                                              (.privateM, self.renderHash(self.booleanPropertiesIVarName)),
                                              (.publicM, self.renderMergeWithModel()),
                                              (.publicM, self.renderMergeWithModelWithInitType()),
                                              (self.isBaseClass ? .publicM : .privateM, self.renderGenerateDictionary()),
                    ] + self.renderIsSetMethods().map { (.publicM, $0) } + self.renderBooleanPropertyAccessorMethods().map { (.publicM, $0) },
                                          properties: properties.map { param, prop in (param, typeFromSchema(param, prop), prop, .readonly) }.sorted { $0.0 < $1.0 },
                                          protocols: protocols
                ),
                                      ObjCIR.Root.classDecl(
                    name: self.builderClassName,
                                          extends: resolveClassName(self.parentDescriptor).map { "\($0)Builder" },
                                          methods: [
                        (.publicM, self.renderBuilderInitWithModel()),
                                              (.publicM, ObjCIR.method("- (\(self.className) *)build") {
                            ["return [[\(self.className) alloc] initWithBuilder:self];"]
                        }),
                                              (.publicM, self.renderBuilderMergeWithModel()),
                    ] + self.renderBuilderPropertySetters().map { (.privateM, $0) },
                                          properties: properties.map { param, prop in (param, typeFromSchema(param, prop), prop, .readwrite) },
                                          protocols: [:]
                ),
                                      ObjCIR.Root.macro("NS_ASSUME_NONNULL_END"),
            ]
    }
}
