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
        return "\(self.className)DirtyProperties"
    }

    var dirtyPropertiesIVarName: String {
        return "\(rootSchema.name.snakeCaseToPropertyName())DirtyProperties"
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
        return ObjCIR.method("- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(\(self.builderClassName) *builder))block") {
            [
                "NSParameterAssert(block);",
                "\(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
                "block(builder);",
                "return [builder build];"
            ]
        }
    }

    func renderMergeWithModel() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)mergeWithModel:(\(self.className) *)modelObject") {
            ["return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];"]
        }
    }

    func renderMergeWithModelWithInitType() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)mergeWithModel:(\(self.className) *)modelObject initType:(PlankModelInitType)initType") {
            [
                "NSParameterAssert(modelObject);",
                "\(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
                "[builder mergeWithModel:modelObject];",
                "return [[\(self.className) alloc] initWithBuilder:builder initType:initType];"
            ]
        }
    }

    func renderStringEnumerationMethods() -> [ObjCIR.Method] {

        func renderToStringMethod(param: String, enumValues: [EnumValue<String>]) -> ObjCIR.Method {
            let enumTypeString = enumTypeName(propertyName: param, className: self.className)
            return ObjCIR.method("extern NSString * _Nonnull \(enumTypeString)ToString(\(enumTypeString) enumType)") {[
                ObjCIR.switchStmt("enumType") {
                    enumValues.map({ (val) -> ObjCIR.SwitchCase in
                        ObjCIR.caseStmt(val.objcOptionName(param: param, className: self.className)) {
                            ["return \(val.defaultValue.objcLiteral());"]
                        }
                    })
                }
            ]}
          }

        func renderFromStringMethod(param: String, enumValues: [EnumValue<String>], defaultValue: EnumValue<String>) -> ObjCIR.Method {
            let enumTypeString = enumTypeName(propertyName: param, className: self.className)

            return ObjCIR.method("extern \(enumTypeString) \(enumTypeString)FromString(NSString * _Nonnull str)") {
              enumValues.map { (val) -> String in
                ObjCIR.ifStmt("[str isEqualToString:\(val.defaultValue.objcLiteral())]") {
                  [
                    "return \(val.objcOptionName(param: param, className: self.className));"
                  ]
                }
              }
              + ["return \(defaultValue.objcOptionName(param: param, className: self.className));"]
            }
        }

      return self.properties.flatMap { (param, schema) -> [ObjCIR.Method] in
        switch schema {
        case .Enum(.String(let enumValues, let defaultValue)):
          return [
            renderToStringMethod(param: param, enumValues: enumValues),
            renderFromStringMethod(param: param, enumValues: enumValues, defaultValue: defaultValue)
          ]
        default:
          return []
        }
      }
    }

    func renderRoots() -> [ObjCIR.Root] {
        let properties: [(Parameter, Schema)] = rootSchema.properties.map { $0 } // Convert [String:Schema] -> [(String, Schema)]

        let protocols: [String : [ObjCIR.Method]] = [
            "NSSecureCoding": [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }]
        ]

        func resolveClassName(_ schema: Schema?) -> String? {
            switch schema {
            case .some(.Object(let root)):
                return root.className(with: self.params)
            case .some(.Reference(with: let fn)):
                return resolveClassName(fn())
            default:
                return nil
            }
        }

        let parentName = resolveClassName(self.parentDescriptor)
        let enumRoots = self.properties.flatMap { (param, schema) -> [ObjCIR.Root] in
            switch schema {
            case .Enum(let enumValues):
                return [ObjCIR.Root.Enum(name: enumTypeName(propertyName: param, className: self.className),
                                        values: enumValues)]
            default: return []
            }
        }

        // TODO: Synthesize oneOf ADT Classes and Class Extension

        let adtRoots = self.properties.flatMap { (param, schema) -> [ObjCIR.Root] in
            switch schema {
            case .OneOf(types: let possibleTypes):
                return adtRootsForSchema(property: param, schemas: possibleTypes)
            case .Array(itemType: .some(let itemType)):
                switch itemType {
                case .OneOf(types: let possibleTypes):
                    return adtRootsForSchema(property: param, schemas: possibleTypes)
                default: return []
                }
            case .Map(valueType: .some(let additionalProperties)):
                switch additionalProperties {
                case .OneOf(types: let possibleTypes):
                    return adtRootsForSchema(property: param, schemas: possibleTypes)
                default: return []
                }
            default: return []
            }
        }

        return [
            ObjCIR.Root.Imports(classNames: self.renderReferencedClasses(), myName: self.className, parentName: parentName)
        ] + adtRoots + enumRoots + [
            ObjCIR.Root.Struct(name: self.dirtyPropertyOptionName,
                               fields: rootSchema.properties.keys
                                .map { "unsigned int \(dirtyPropertyOption(propertyName: $0, className: self.className)):1;" }
            ),
            ObjCIR.Root.Category(className: self.className,
                                 categoryName: nil,
                                 methods: [],
                                 properties: [(self.dirtyPropertiesIVarName, "struct \(self.dirtyPropertyOptionName)", .Integer, .ReadWrite)]),
            ObjCIR.Root.Category(className: self.builderClassName,
                                 categoryName: nil,
                                 methods: [],
                                 properties: [(self.dirtyPropertiesIVarName, "struct \(self.dirtyPropertyOptionName)", .Integer, .ReadWrite)])
        ] + self.renderStringEnumerationMethods().map { ObjCIR.Root.Function($0) } + [
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_BEGIN"),
            ObjCIR.Root.Class(
                name: self.className,
                extends: parentName,
                methods: [
                    (self.isBaseClass ? .Public : .Private, self.renderClassName()),
                    (self.isBaseClass ? .Public : .Private, self.renderPolymorphicTypeIdentifier()),
                    (self.isBaseClass ? .Public : .Private, self.renderModelObjectWithDictionary()),
                    (.Private, self.renderDesignatedInit()),
                    (self.isBaseClass ? .Public : .Private, self.renderInitWithModelDictionary()),
                    (.Public, self.renderInitWithBuilder()),
                    (self.isBaseClass ? .Public : .Private, self.renderInitWithBuilderWithInitType()),
                    (.Private, self.renderDebugDescription()),
                    (.Public, self.renderCopyWithBlock()),
                    (.Private, self.renderIsEqual()),
                    (.Public, self.renderIsEqualToClass()),
                    (.Private, self.renderHash()),
                    (.Public, self.renderMergeWithModel()),
                    (.Public, self.renderMergeWithModelWithInitType())
                ],
                properties: properties.map { param, schema in (param, objcClassFromSchema(param, schema), schema, .ReadOnly) },
                protocols: protocols
            ),
            ObjCIR.Root.Class(
                name: self.builderClassName,
                extends: resolveClassName(self.parentDescriptor).map { "\($0)Builder"},
                methods: [
                    (.Public, self.renderBuilderInitWithModel()),
                    (.Public, ObjCIR.method("- (\(self.className) *)build") {
                        ["return [[\(self.className) alloc] initWithBuilder:self];"]
                    }),
                    (.Public, self.renderBuilderMergeWithModel())
                    ] + self.renderBuilderPropertySetters().map { (.Private, $0) },
                properties: properties.map { param, schema in (param, objcClassFromSchema(param, schema), schema, .ReadWrite) },
                protocols: [:]),
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_END")
        ]
    }
}
