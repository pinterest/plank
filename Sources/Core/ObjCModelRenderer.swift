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

      return self.properties.flatMap { (param, prop) -> [ObjCIR.Method] in
        switch prop.schema {
        case .enumT(.string(let enumValues, let defaultValue)):
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
        let properties: [(Parameter, SchemaObjectProperty)] = rootSchema.properties.map { $0 } // Convert [String:Schema] -> [(String, Schema)]

        let protocols: [String : [ObjCIR.Method]] = [
            "NSSecureCoding": [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }]
        ]

        func resolveClassName(_ schema: Schema?) -> String? {
            switch schema {
            case .some(.object(let root)):
                return root.className(with: self.params)
            case .some(.reference(with: let ref)):
                return resolveClassName(ref.force())
            default:
                return nil
            }
        }

        let parentName = resolveClassName(self.parentDescriptor)
        let enumRoots = self.properties.flatMap { (param, prop) -> [ObjCIR.Root] in
            switch prop.schema {
            case .enumT(let enumValues):
                return [ObjCIR.Root.enumDecl(name: enumTypeName(propertyName: param, className: self.className),
                                        values: enumValues)]
            default: return []
            }
        }

        // TODO: Synthesize oneOf ADT Classes and Class Extension
        // TODO (rmalik): Clean this up, too much copy / paste here to support oneOf cases
        let adtRoots = self.properties.flatMap { (param, prop) -> [ObjCIR.Root] in
            switch prop.schema {
            case .oneOf(types: let possibleTypes):
                let objProps = possibleTypes.map { SchemaObjectProperty(schema: $0, nullability: $0.isObjCPrimitiveType ? nil : .nullable)}
                return adtRootsForSchema(property: param, schemas: objProps)
            case .array(itemType: .some(let itemType)):
                switch itemType {
                case .oneOf(types: let possibleTypes):
                    let objProps = possibleTypes.map { SchemaObjectProperty(schema: $0, nullability: $0.isObjCPrimitiveType ? nil : .nullable)}
                    return adtRootsForSchema(property: param, schemas: objProps)
                default: return []
                }
            case .map(valueType: .some(let additionalProperties)):
                switch additionalProperties {
                case .oneOf(types: let possibleTypes):
                    let objProps = possibleTypes.map { SchemaObjectProperty(schema: $0, nullability: $0.isObjCPrimitiveType ? nil : .nullable)}
                    return adtRootsForSchema(property: param, schemas: objProps)
                default: return []
                }
            default: return []
            }
        }

        return [
            ObjCIR.Root.imports(classNames: self.renderReferencedClasses(), myName: self.className, parentName: parentName)
        ] + adtRoots + enumRoots + [
            ObjCIR.Root.structDecl(name: self.dirtyPropertyOptionName,
                               fields: rootSchema.properties.keys
                                .map { "unsigned int \(dirtyPropertyOption(propertyName: $0, className: self.className)):1;" }
            ),
            ObjCIR.Root.category(className: self.className,
                                 categoryName: nil,
                                 methods: [],
                                 properties: [(self.dirtyPropertiesIVarName, "struct \(self.dirtyPropertyOptionName)",
                                    SchemaObjectProperty(schema: .integer, nullability: nil),
                                    .readwrite)]),
            ObjCIR.Root.category(className: self.builderClassName,
                                 categoryName: nil,
                                 methods: [],
                                 properties: [(self.dirtyPropertiesIVarName, "struct \(self.dirtyPropertyOptionName)",
                                    SchemaObjectProperty(schema: .integer, nullability: nil),
                                    .readwrite)])
        ] + self.renderStringEnumerationMethods().map { ObjCIR.Root.function($0) } + [
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
                    (.publicM, self.renderIsEqualToClass()),
                    (.privateM, self.renderHash()),
                    (.publicM, self.renderMergeWithModel()),
                    (.publicM, self.renderMergeWithModelWithInitType()),
                    (self.isBaseClass ? .publicM : .privateM, self.renderGenerateDictionary())

                ],
                properties: properties.map { param, prop in (param, objcClassFromSchema(param, prop.schema), prop, .readonly) },
                protocols: protocols
            ),
            ObjCIR.Root.classDecl(
                name: self.builderClassName,
                extends: resolveClassName(self.parentDescriptor).map { "\($0)Builder"},
                methods: [
                    (.publicM, self.renderBuilderInitWithModel()),
                    (.publicM, ObjCIR.method("- (\(self.className) *)build") {
                        ["return [[\(self.className) alloc] initWithBuilder:self];"]
                    }),
                    (.publicM, self.renderBuilderMergeWithModel())
                    ] + self.renderBuilderPropertySetters().map { (.privateM, $0) },
                properties: properties.map { param, prop in (param, objcClassFromSchema(param, prop.schema), prop, .readwrite) },
                protocols: [:]),
            ObjCIR.Root.macro("NS_ASSUME_NONNULL_END")
        ]
    }
}
