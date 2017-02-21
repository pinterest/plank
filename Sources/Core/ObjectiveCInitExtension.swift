//
//  ObjectiveCInitExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/14/17.
//
//

import Foundation

let dateValueTransformerKey = "kPINModelDateValueTransformerKey"

extension ObjCRootsRenderer {

    func renderModelObjectWithDictionary() -> ObjCIR.Method {
        return ObjCIR.method("+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary") {
            ["return [[self alloc] initWithModelDictionary:dictionary];"]
        }
    }

    func renderDesignatedInit() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)init") {
            [
                "return [self initWithModelDictionary:@{}];"
            ]
        }
    }

    func renderInitWithBuilder() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithBuilder:(\(builderClassName) *)builder") {
            [
                "NSParameterAssert(builder);",
                "return [self initWithBuilder:builder initType:PIModelInitTypeDefault];"
            ]
        }
    }

    func renderPostInitNotification(type: String) -> String {
      return "[[NSNotificationCenter defaultCenter] postNotificationName:kPINModelDidInitializeNotification object:self userInfo:@{ kPINModelInitTypeKey : @(\(type)) }];"
    }

    func renderInitWithBuilderWithInitType() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithBuilder:(\(builderClassName) *)builder initType:(PIModelInitType)initType") {
            [
                "NSParameterAssert(builder);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                    ObjCIR.ifStmt("!(self = [super initWithBuilder:builder initType:initType])") { ["return self;"] },
                self.properties.map { (name, _) in
                    "_\(name.snakeCaseToPropertyName()) = builder.\(name.snakeCaseToPropertyName());"
                    }.joined(separator: "\n"),
                "_\(self.dirtyPropertiesIVarName) = builder.\(self.dirtyPropertiesIVarName);",
                ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                    [renderPostInitNotification(type: "initType")]
                },
                "return self;"
            ]
        }
    }

    func renderInitWithModelDictionary() -> ObjCIR.Method {
        func renderPropertyInit(
            _ propertyToAssign: String,
            _ rawObjectName: String,
            schema: Schema,
            firstName: String, // TODO: HACK to get enums to work (not clean)
            counter: Int = 0
            ) -> [String] {
            switch schema {
            case .Array(itemType: .some(let itemType)):
                let currentResult = "result\(counter)"
                let currentTmp = "tmp\(counter)"
                let currentObj = "obj\(counter)"
                return [
                    "NSArray *items = \(rawObjectName);",
                    "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items.count];",
                    ObjCIR.forStmt("id \(currentObj) in items") { [
                        ObjCIR.ifStmt("[\(currentObj) isEqual:[NSNull null]] == NO") { [
                            "id \(currentTmp) = nil;",
                            renderPropertyInit(currentTmp, currentObj, schema: itemType, firstName: firstName, counter: counter + 1).joined(separator: "\n"),
                            ObjCIR.ifStmt("\(currentTmp) != nil") {[
                                "[\(currentResult) addObject:\(currentTmp)];"
                                ]}
                            ]}
                        ]},
                    "\(propertyToAssign) = \(currentResult);"
                ]
            case .Map(valueType: .some(let valueType)) where valueType.isObjCPrimitiveType == false:
                let currentResult = "result\(counter)"
                let currentItems = "items\(counter)"
                let (currentKey, currentObj, currentStop) = ("key\(counter)", "obj\(counter)", "stop\(counter)")
                return [
                    "NSDictionary *\(currentItems) = \(rawObjectName);",
                    "NSMutableDictionary *\(currentResult) = [NSMutableDictionary dictionaryWithCapacity:\(currentItems).count];",
                    ObjCIR.stmt(
                        ObjCIR.msg(currentItems,
                                   ("enumerateKeysAndObjectsUsingBlock",
                                    ObjCIR.block(["NSString *  _Nonnull \(currentKey)",
                                        "id  _Nonnull \(currentObj)",
                                        "__unused BOOL * _Nonnull \(currentStop)"]) {
                                            [
                                                ObjCIR.ifStmt("\(currentObj) != nil && [\(currentObj) isEqual:[NSNull null]] == NO") {
                                                    renderPropertyInit("\(currentResult)[\(currentKey)]", currentObj, schema: valueType, firstName: firstName, counter: counter + 1)
                                                }
                                            ]
                                   })
                        )
                    ),
                    "\(propertyToAssign) = \(currentResult);"
                ]
            case .Float:
                return ["\(propertyToAssign) = [\(rawObjectName) doubleValue];"]
            case .Integer:
                return ["\(propertyToAssign) = [\(rawObjectName) integerValue];"]
            case .Boolean:
                return ["\(propertyToAssign) = [\(rawObjectName) boolValue];"]
            case .String(format: .some(.Uri)):
                return ["\(propertyToAssign) = [NSURL URLWithString:\(rawObjectName)];"]
            case .String(format: .some(.DateTime)):
                return ["\(propertyToAssign) = [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] transformedValue:\(rawObjectName)];"]
            case .Reference(with: let refFunc):
                return refFunc().map {
                    renderPropertyInit(propertyToAssign, rawObjectName, schema: $0, firstName: firstName, counter: counter)
                    } ?? {
                        assert(false, "TODO: Forward optional across methods")
                        return []
                    }()
            case .Enum(.Integer(let variants)):
                return renderPropertyInit(propertyToAssign, rawObjectName, schema: .Integer, firstName: firstName, counter: counter)
            case .Enum(.String(let variants)):
                return ["\(propertyToAssign) = \(enumFromStringMethodName(propertyName: firstName, className: className))(value);"]
            case .OneOf(types: let schemas):
                func loop(schema: Schema) -> String {
                    switch schema {
                    case .Object(let objectRoot):
                        return ObjCIR.ifStmt("[\(rawObjectName)[\("type".objcLiteral())] isEqualToString:\(objectRoot.typeIdentifier.objcLiteral())]") {[
                            "\(propertyToAssign) = [\(objectRoot.className(with: self.params)) modelObjectWithDictionary:\(rawObjectName)];"
                            ]}
                    case .Reference(with: let refFunc):
                        return refFunc().map(loop) ?? {
                            assert(false, "TODO: Forward optional across methods")
                            return ""
                            }()
                    default:
                        assert(false, "Unsupported OneOf type (for now)")
                        return ""
                    }
                }

                return schemas.map(loop)
            case .Object(let objectRoot):
                return ["\(propertyToAssign) = [\(objectRoot.className(with: self.params)) modelObjectWithDictionary:\(rawObjectName)];"]
            default:
                return ["\(propertyToAssign) = \(rawObjectName);"]
            }
        }

        return ObjCIR.method("- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary") {
            let x: [String] = self.properties.map { (name, schema) in
                ObjCIR.ifStmt("[key isEqualToString:\(name.objcLiteral())]") {
                    [
                        "id value = valueOrNil(modelDictionary, \(name.objcLiteral()));",
                        ObjCIR.ifStmt("value != nil") {
                            renderPropertyInit("self->_\(name.snakeCaseToPropertyName())", "value", schema: schema, firstName: name)
                        },
                        "self->_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: name, className: className)) = 1;"
                    ]
                }
            }

            return [
                "NSParameterAssert(modelDictionary);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                "if (!(self = [super initWithModelDictionary:modelDictionary])) { return self; }",
                ObjCIR.stmt(
                    ObjCIR.msg("modelDictionary",
                               ("enumerateKeysAndObjectsUsingBlock", ObjCIR.block(["NSString *  _Nonnull key",
                                                                                   "id  _Nonnull obj",
                                                                                   "__unused BOOL * _Nonnull stop"]) {
                                                                                    x
                                }
                        )
                )),
                ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                    [renderPostInitNotification(type: "PIModelInitTypeDefault")]
                },
                "return self;"
            ]
        }
    }
}
