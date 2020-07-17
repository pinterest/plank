//
//  ObjectiveCInitExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/14/17.
//
//

import Foundation

let dateValueTransformerKey = "kPlankDateValueTransformerKey"

extension ObjCFileRenderer {
    func renderPostInitNotification(type: String) -> String {
        return "[[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(\(type)) }];"
    }
}

extension ObjCModelRenderer {
    func renderModelObjectWithDictionary() -> ObjCIR.Method {
        return ObjCIR.method("+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary") {
            ["return [[self alloc] initWithModelDictionary:dictionary];"]
        }
    }

    func renderModelObjectWithDictionaryError() -> ObjCIR.Method {
        return ObjCIR.method("+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing *)error") {
            ["return [[self alloc] initWithModelDictionary:dictionary error:error];"]
        }
    }

    func renderDesignatedInit() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)init") {
            ["return [self initWithModelDictionary:@{} error:NULL];"]
        }
    }

    func renderInitWithModelDictionary() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary") {
            ["return [self initWithModelDictionary:modelDictionary error:NULL];"]
        }
    }

    func renderInitWithBuilder() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithBuilder:(\(builderClassName) *)builder") {
            [
                "NSParameterAssert(builder);",
                "return [self initWithBuilder:builder initType:PlankModelInitTypeDefault];",
            ]
        }
    }

    func renderInitWithBuilderWithInitType() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithBuilder:(\(builderClassName) *)builder initType:(PlankModelInitType)initType") {
            [
                "NSParameterAssert(builder);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                    ObjCIR.ifStmt("!(self = [super initWithBuilder:builder initType:initType])") { ["return self;"] },
                self.properties.filter { (_, schema) -> Bool in
                    !schema.schema.isBoolean()
                }.map { name, _ in
                    "_\(Languages.objectiveC.snakeCaseToPropertyName(name)) = builder.\(Languages.objectiveC.snakeCaseToPropertyName(name));"
                }.joined(separator: "\n"),
            ] +
                self.properties.filter { (_, schema) -> Bool in
                    schema.schema.isBoolean()
                }.map { name, _ in
                    "_\(self.booleanPropertiesIVarName).\(booleanPropertyOption(propertyName: name, className: self.className)) = builder.\(Languages.objectiveC.snakeCaseToPropertyName(name)) == 1;"
                } + [
                    "_\(self.dirtyPropertiesIVarName) = builder.\(self.dirtyPropertiesIVarName);",
                    ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                        [renderPostInitNotification(type: "initType")]
                    },
                    "return self;",
                ]
        }
    }

    func expectedObjectType(schema: Schema) -> String? {
        switch schema {
        case .object,
             .map(valueType: _):
            return "NSDictionary"
        case .array(itemType: _),
             .set(itemType: _):
            return "NSArray"
        case .integer,
             .float,
             .boolean,
             .enumT(.integer):
            return "NSNumber"
        case .string(format: _),
             .enumT(.string):
            return "NSString"
        default:
            return nil
        }
    }

    public func renderInitWithModelDictionaryError() -> ObjCIR.Method {
        func renderPropertyInit(
            _ propertyToAssign: String,
            _ rawObjectName: String,
            keyPath: [String],
            schema: Schema,
            firstName: String, // TODO: HACK to get enums to work (not clean)
            counter: Int = 0,
            dirtyPropertyName: String? = nil,
            needsTypeCheck: Bool = true
        ) -> [String] {
            func renderTypeCheck(_ body: () -> [String]) -> [String] {
                guard needsTypeCheck else { return body() }
                guard let kindOf = expectedObjectType(schema: schema) else { return body() }
                let key = keyPath.count == 1 ? keyPath[0] : "[@[\(keyPath.joined(separator: ", "))] componentsJoinedByString:@\".\"]"
                return [
                    ObjCIR.ifStmt("!error || [\(rawObjectName) isKindOfClass:[\(kindOf) class]]", body: body) +
                        ObjCIR.elseStmt {
                            ((dirtyPropertyName != nil) ? ["self->_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: dirtyPropertyName!, className: className)) = 0;"] : []) +
                                ["*error = PlankTypeError(\(key), [\(kindOf) class], [\(rawObjectName) class]);"]

                        },
                ]
            }

            switch schema {
            case let .array(itemType: .some(itemType)):
                let currentResult = "result\(counter)"
                let currentTmp = "tmp\(counter)"
                let currentObj = "obj\(counter)"
                if itemType.isPrimitiveType {
                    return renderTypeCheck { [
                        "\(propertyToAssign) = \(rawObjectName);",
                    ] }
                }
                let propertyInit = renderPropertyInit(currentTmp, currentObj, keyPath: keyPath + ["?".objcLiteral()], schema: itemType, firstName: firstName, counter: counter + 1).joined(separator: "\n")
                return renderTypeCheck { [
                    "NSArray *items = \(rawObjectName);",
                    "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items.count];",
                    ObjCIR.forStmt("id \(currentObj) in items") { [
                        ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                            "id \(currentTmp) = nil;",
                            propertyInit,
                            ObjCIR.ifStmt("\(currentTmp) != nil") { [
                                "[\(currentResult) addObject:\(currentTmp)];",
                            ] },
                        ] },
                    ] },
                    "\(propertyToAssign) = \(currentResult);",
                ] }
            case let .set(itemType: .some(itemType)):
                let currentResult = "result\(counter)"
                let currentTmp = "tmp\(counter)"
                let currentObj = "obj\(counter)"
                if itemType.isPrimitiveType {
                    return renderTypeCheck { [
                        "NSArray *items = \(rawObjectName);",
                        "\(propertyToAssign) = [NSSet setWithArray:items];",
                    ] }
                }
                let propertyInit = renderPropertyInit(currentTmp, currentObj, keyPath: keyPath + ["?".objcLiteral()], schema: itemType, firstName: firstName, counter: counter + 1).joined(separator: "\n")
                return renderTypeCheck { [
                    "NSArray *items = \(rawObjectName);",
                    "NSMutableSet *\(currentResult) = [NSMutableSet setWithCapacity:items.count];",
                    ObjCIR.forStmt("id \(currentObj) in items") { [
                        ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                            "id \(currentTmp) = nil;",
                            propertyInit,
                            ObjCIR.ifStmt("\(currentTmp) != nil") { [
                                "[\(currentResult) addObject:\(currentTmp)];",
                            ] },
                        ] },
                    ] },
                    "\(propertyToAssign) = \(currentResult);",
                ] }
            case let .map(valueType: .some(valueType)) where valueType.isPrimitiveType == false:
                let currentResult = "result\(counter)"
                let currentItems = "items\(counter)"
                let (currentKey, currentObj, currentStop) = ("key\(counter)", "obj\(counter)", "stop\(counter)")
                return renderTypeCheck { [
                    "NSDictionary *\(currentItems) = \(rawObjectName);",
                    "NSMutableDictionary *\(currentResult) = [NSMutableDictionary dictionaryWithCapacity:\(currentItems).count];",
                    ObjCIR.stmt(
                        ObjCIR.msg(currentItems,
                                   ("enumerateKeysAndObjectsUsingBlock",
                                    ObjCIR.block(["NSString *  _Nonnull \(currentKey)",
                                                  "id  _Nonnull \(currentObj)",
                                                  "__unused BOOL * _Nonnull \(currentStop)"]) {
                                        [
                                            ObjCIR.ifStmt("\(currentObj) != nil && \(currentObj) != (id)kCFNull") {
                                                renderPropertyInit("\(currentResult)[\(currentKey)]", currentObj, keyPath: keyPath + [currentKey], schema: valueType, firstName: firstName, counter: counter + 1)
                                            },
                                        ]
                        }))
                    ),
                    "\(propertyToAssign) = \(currentResult);",
                ] }
            case .float:
                return renderTypeCheck { ["\(propertyToAssign) = [\(rawObjectName) doubleValue];"] }
            case .integer:
                return renderTypeCheck { ["\(propertyToAssign) = [\(rawObjectName) integerValue];"] }
            case .boolean:
                return renderTypeCheck { ["\(propertyToAssign) = [\(rawObjectName) boolValue] & 0x1;"] }
            case .string(format: .some(.uri)):
                return renderTypeCheck { ["\(propertyToAssign) = [NSURL URLWithString:\(rawObjectName)];"] }
            case .string(format: .some(.dateTime)):
                return renderTypeCheck { ["\(propertyToAssign) = [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] transformedValue:\(rawObjectName)];"] }
            case let .reference(with: ref):
                return ref.force().map {
                    renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: $0, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName)
                } ?? {
                    assert(false, "TODO: Forward optional across methods")
                    return []
                }()
            case .enumT(.integer):
                let typeName = enumTypeName(propertyName: firstName, className: className)
                return renderTypeCheck { ["\(propertyToAssign) = (\(typeName))[\(rawObjectName) integerValue];"] }
            case .enumT(.string):
                return renderTypeCheck { ["\(propertyToAssign) = \(enumFromStringMethodName(propertyName: firstName, className: className))(value);"] }
            case let .object(objectRoot):
                return renderTypeCheck { ["\(propertyToAssign) = [\(objectRoot.className(with: self.params)) modelObjectWithDictionary:\(rawObjectName)];"] }
            case let .oneOf(types: schemas):
                // TODO: Update to create ADT objects
                let adtClassName = typeFromSchema(firstName, schema.nonnullProperty()).trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                func loop(schema: Schema) -> String {
                    func transformToADTInit(_ lines: [String]) -> [String] {
                        if let assignmentLine = lines.last {
                            let propAssignmentPrefix = "\(propertyToAssign) = "
                            if assignmentLine.hasPrefix(propAssignmentPrefix) {
                                let startIndex = propAssignmentPrefix.endIndex
                                let propertyInitStatement = String(assignmentLine[startIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: " ;"))
                                let adtInitStatement = propAssignmentPrefix + "[\(adtClassName) objectWith\(ObjCADTRenderer.objectName(schema)):\(propertyInitStatement)];"
                                return lines.dropLast() + [adtInitStatement]
                            }
                        }
                        return lines
                    }

                    switch schema {
                    case let .object(objectRoot):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSDictionary class]] && [\(rawObjectName)[\("type".objcLiteral())] isEqualToString:\(objectRoot.typeIdentifier.objcLiteral())]") {
                            transformToADTInit(["\(propertyToAssign) = [\(objectRoot.className(with: self.params)) modelObjectWithDictionary:\(rawObjectName)];"])
                        }
                    case let .reference(with: ref):
                        return ref.force().map(loop) ?? {
                            assert(false, "TODO: Forward optional across methods")
                            return ""
                        }()
                    case .float:
                        let encodingConditions = [
                            "strcmp([\(rawObjectName) objCType], @encode(float)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(double)) == 0",
                        ]

                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSNumber class]] && (\(encodingConditions.joined(separator: " ||\n")))") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: .float, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .integer, .enumT(.integer):
                        let encodingConditions = [
                            "strcmp([\(rawObjectName) objCType], @encode(int)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(unsigned int)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(short)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(unsigned short)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(long)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(long long)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(unsigned long)) == 0",
                            "strcmp([\(rawObjectName) objCType], @encode(unsigned long long)) == 0",
                        ]
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSNumber class]] && (\(encodingConditions.joined(separator: " ||\n")))") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }

                    case .boolean:
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSNumber class]] && strcmp([\(rawObjectName) objCType], @encode(BOOL)) == 0") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .array(itemType: _):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSArray class]]") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .set(itemType: _):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSSet class]]") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .map(valueType: _):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSDictionary class]]") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .string(.some(.uri)):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSString class]] && [NSURL URLWithString:\(rawObjectName)] != nil") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .string(.some(.dateTime)):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSString class]] && [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] transformedValue:\(rawObjectName)] != nil") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .string(.some), .string(.none), .enumT(.string):
                        return ObjCIR.ifStmt("[\(rawObjectName) isKindOfClass:[NSString class]]") {
                            transformToADTInit(renderPropertyInit(propertyToAssign, rawObjectName, keyPath: keyPath, schema: schema, firstName: firstName, counter: counter, dirtyPropertyName: dirtyPropertyName, needsTypeCheck: false))
                        }
                    case .oneOf(types: _):
                        fatalError("Nested oneOf types are unsupported at this time. Please file an issue if you require this.")
                    }
                }

                return schemas.map(loop)
            default:
                switch schema.memoryAssignmentType() {
                case .copy:
                    return renderTypeCheck { ["\(propertyToAssign) = [\(rawObjectName) copy];"] }
                default:
                    return renderTypeCheck { ["\(propertyToAssign) = \(rawObjectName);"] }
                }
            }
        }

        return ObjCIR.method("- (instancetype)initWithModelDictionary:(NS_VALID_UNTIL_END_OF_SCOPE NSDictionary *)modelDictionary error:(NSError *__autoreleasing *)error") {
            [
                "NSParameterAssert(modelDictionary);",
                ObjCIR.ifStmt("!modelDictionary") { ["return self;"] },
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                    "if (!(self = [super initWithModelDictionary:modelDictionary error:error])) { return self; }",
                self.properties.map { name, prop in
                    ObjCIR.scope { [
                        "__unsafe_unretained id value = modelDictionary[\(name.objcLiteral())];",
                        ObjCIR.ifStmt("value != nil") { [
                            "self->_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: name, className: className)) = 1;",
                            ObjCIR.ifStmt("value != (id)kCFNull") {
                                switch prop.schema {
                                case .boolean:
                                    return renderPropertyInit("self->_\(booleanPropertiesIVarName).\(booleanPropertyOption(propertyName: name, className: className))", "value", keyPath: [name.objcLiteral()], schema: prop.schema, firstName: name, dirtyPropertyName: name)
                                default:
                                    return renderPropertyInit("self->_\(Languages.objectiveC.snakeCaseToPropertyName(name))", "value", keyPath: [name.objcLiteral()], schema: prop.schema, firstName: name, dirtyPropertyName: name)
                                }
                            },
                        ] },
                    ] }
                }.joined(separator: "\n"),
                ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                    [renderPostInitNotification(type: "PlankModelInitTypeDefault")]
                },
                "return self;",
            ]
        }
    }
}
