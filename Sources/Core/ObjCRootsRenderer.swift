//
//  ObjCRootsRenderer.swift
//  Plank
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

let rootNSObject = SchemaObjectRoot(name: "NSObject", properties: [:], extends: nil, algebraicTypeIdentifier: nil)

public struct ObjCRootsRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }

    // MARK: Properties

    var className: String {
        return self.rootSchema.className(with: self.params)
    }

    var builderClassName: String {
        return "\(self.className)Builder"
    }

    var dirtyPropertyOptionName: String {
        return "\(self.className)DirtyProperties"
    }

    var parentDescriptor: Schema? {
        return self.rootSchema.extends.flatMap { $0() }
    }

    var properties: [(Parameter, Schema)] {
        return self.rootSchema.properties.map { $0 }
    }

    var dirtyPropertiesIVarName: String {
        return "\(rootSchema.name.snakeCaseToPropertyName())DirtyProperties"
    }

    var isBaseClass: Bool {
        return rootSchema.extends == nil
    }

    func renderReferencedClasses() -> Set<String> {
        // Referenced Classes
        // The current class header
        // Plank Runtime header
        func referencedClassNames(schema: Schema) -> [String] {
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

        return Set(rootSchema.properties.values
                    .flatMap(referencedClassNames))
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
            return enumTypeName(propertyName: param, className: self.className)
        case .Object(let objSchemaRoot):
            return "\(objSchemaRoot.className(with: self.params)) *"
        case .Reference(with: let fn):
            switch fn() {
            case .some(.Object(let schemaRoot)):
                return objcClassFromSchema(param, .Object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        case .OneOf(types: let schemaTypes):
            // TODO replace this with ADT generated name
            func inheritanceChain(schema: Schema?) -> [SchemaObjectRoot] {
                switch schema {
                case .some(.Object(let root)):
                    return [root] + inheritanceChain(schema: root.extends.flatMap { $0() })
                case .some(.Reference(with: let fn)):
                    return inheritanceChain(schema: fn())
                default:
                    return []
                }
            }

            let chains: [[SchemaObjectRoot]] = schemaTypes
                .map(inheritanceChain)
                .map { $0.reversed() }

            let commonParent = chains[0].enumerated().filter { idx, val in
                chains.filter { $0[idx] == val }.count == chains.count
                }.last.map {$0.1}

            let schemaRoot = commonParent ?? rootNSObject
            return "__kindof \((schemaRoot == commonParent ? schemaRoot.className(with: self.params) : schemaRoot.name)) *"
        }
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

    func renderDebugDescription() -> ObjCIR.Method {
        func formatParam(_ param: String, _ schema: Schema) -> String {
            let propIVarName = "_\(param.snakeCaseToPropertyName())"
            switch schema {
            case .Enum(.String(_)):
                return enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))"
            case .Boolean, .Float, .Integer:
                return "@(\(propIVarName))"
            case .Enum(.Integer(_)):
                return "@(\(propIVarName))"
            case .String(format: _):
                return propIVarName
            case .Array(itemType: _):
                return propIVarName
            case .Map(valueType: _):
                return propIVarName
            case .Object(_):
                return propIVarName
            case .OneOf(types: _):
                return propIVarName
            case .Reference(with: let fn):
                switch fn() {
                case .some(.Object(let schemaRoot)):
                    return formatParam(param, .Object(schemaRoot))
                default:
                    fatalError("Bad reference found in schema for class: \(self.className)")
                }
            }
        }

        let props = self.properties.map { (param, schema) -> String in
            ObjCIR.ifStmt("props.\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                let ivarName = "_\(param.snakeCaseToPropertyName())"
                return ["[descriptionFields addObject:[\((ivarName + " = ").objcLiteral()) stringByAppendingFormat:\("%@".objcLiteral()), \(formatParam(param, schema))]];"]
            }
        }.joined(separator: "\n")

        let printFormat = "\(self.className) = {\\n%@\\n}".objcLiteral()
        return ObjCIR.method("- (NSString *)debugDescription") {[
                "NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:\("\\n".objcLiteral())];",
                "NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:\(self.properties.count)];",
                "[descriptionFields addObject:parentDebugDescription];",
                "struct \(self.dirtyPropertyOptionName) props = _\(self.dirtyPropertiesIVarName);",
                props,
                "return [NSString stringWithFormat:\(printFormat), debugDescriptionForFields(descriptionFields)];"
        ]}
    }

    func renderCopyWithBlock() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)copyWithBlock:(PINMODEL_NOESCAPE void (^)(\(self.builderClassName) *builder))block") {
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
            ["return [self mergeWithModel:modelObject initType:PIModelInitTypeFromMerge];"]
        }
    }

    func renderMergeWithModelWithInitType() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)mergeWithModel:(\(self.className) *)modelObject initType:(PIModelInitType)initType") {
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
        return [
            ObjCIR.Root.Imports(classNames: self.renderReferencedClasses(), myName: self.className, parentName: parentName)
        ] + enumRoots + [
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
