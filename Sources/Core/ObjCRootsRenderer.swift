//
//  ObjCRootsRenderer.swift
//  Plank
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

let DateValueTransformerKey = "kPINModelDateValueTransformerKey"

struct ObjCRootsRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }

    // MARK: Properties

    var className: String {
        get {
            return self.rootSchema.className(with: self.params)
        }
    }

    var builderClassName: String {
        get {
            return "\(self.className)Builder"
        }
    }

    var dirtyPropertyOptionName: String {
        get {
            return "\(self.className)DirtyProperties"
        }
    }

    var parentDescriptor: Schema?  {
        get {
            return self.rootSchema.extends.flatMap { $0() }
        }
    }


    var properties: [(Parameter, Schema)] {
        get {
            return self.rootSchema.properties.map { $0 }
        }
    }

    var dirtyPropertiesIVarName: String {
        get {
            return "\(rootSchema.name.snakeCaseToPropertyName())DirtyProperties"
        }
    }

    var isBaseClass: Bool {
        get {
            return rootSchema.extends == nil
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

    func renderModelObjectWithDictionary() -> ObjCIR.Method {
        return ObjCIR.method("+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary") {
            ["return [[self alloc] initWithDictionary:dictionary];"]
        }
    }


    func renderDesignatedInit() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)init") {
            [
                "return [self initWithDictionary:@{}];",
            ]
        }
    }

    // MARK: Hash Method - Inspired from Mike Ash article on Equality / Hashing
    // https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
    func renderHash() -> ObjCIR.Method {
        func schemaHashStatement(with param: Parameter, for schema: Schema) -> String {
            switch schema {
            case .Enum(_), .Integer:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return "_\(param)"
            case .Float:
                return " [@(_\(param)) hash]"
            case .Boolean:
                // Values 1231 for true and 1237 for false are adopted from the Java hashCode specification
                // http://docs.oracle.com/javase/7/docs/api/java/lang/Boolean.html#hashCode
                return "(_\(param) ? 1231 : 1237)"
            case .Reference(with: let fn):
                switch fn() {
                case .some(.Object(let schemaRoot)):
                    return schemaHashStatement(with: param, for: .Object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            default:
                return "[_\(param) hash]"
            }
        }

        let rootHashStatement = self.isBaseClass ? ["17"] : ["[super hash]"];
        let propReturnStatements = rootHashStatement + self.properties.map { param, schema -> String in
            let formattedParam = param.snakeCaseToPropertyName()
            return schemaHashStatement(with: formattedParam, for: schema)
        }

        return ObjCIR.method("- (NSUInteger)hash") {[
            "return (",
                -->[propReturnStatements.map{ "(\($0))" }.joined(separator: " ^\n")],
            ");"
        ]}
    }

    // MARK: Equality Methods inspired from NSHipster article on Equality: http://nshipster.com/equality/
    func renderIsEqualToClass() -> ObjCIR.Method {
        func schemaIsEqualStatement(with param: Parameter, for schema: Schema) -> String {
            switch schema {
            case .Integer, .Float, .Enum(_), .Boolean:
                // - The value equality statement is sufficient for equality testing
                // - All enum types are treated as Integers so we do not need to treat String Enumerations differently
                return ""
            case .Map(_):
                return ObjCIR.msg("_\(param)", ("isEqualToDictionary", "anObject.\(param)"))
            case .String(format: .some(.DateTime)):
                return ObjCIR.msg("_\(param)", ("isEqualToDate", "anObject.\(param)"))
            case .String(format: .none),
                 .String(format: .some(.Email)),
                 .String(format: .some(.Hostname)),
                 .String(format: .some(.Ipv4)),
                 .String(format: .some(.Ipv6)):
                return ObjCIR.msg("_\(param)", ("isEqualToString", "anObject.\(param)"))
            case .OneOf(types:_), .Object(_), .Array(_), .String(format: .some(.Uri)):
                return ObjCIR.msg("_\(param)", ("isEqual", "anObject.\(param)"))
            case .Reference(with: let fn):
                switch fn() {
                case .some(.Object(let schemaRoot)):
                    return schemaIsEqualStatement(with: param, for: .Object(schemaRoot))
                default:
                    fatalError("Bad reference found for schema parameter: \(param)")
                }
            }
        }

        // Performance optimization - compare primitives before resorting to more expensive `isEqual` calls
        let sortedProps = self.properties.sorted { $0.0.1.isObjCPrimitiveType }

        let propReturnStmts = sortedProps.map { param, schema -> String in
            let formattedParam = param.snakeCaseToPropertyName()
            let pointerEqStmt = "_\(formattedParam) == anObject.\(formattedParam)"
            let deepEqStmt = schemaIsEqualStatement(with: formattedParam, for: schema)
            return [pointerEqStmt, deepEqStmt].filter { $0 != "" }.joined(separator: " || ")
        }

        return ObjCIR.method("- (BOOL)isEqualTo\(self.rootSchema.name.snakeCaseToCamelCase()):(\(self.className) *)anObject") {
            [
                "return (",
                -->[(["anObject != nil", "self == anObject"] + propReturnStmts)
                        .map{ "(\($0))" }.joined(separator: " &&\n")],
                ");"
            ]
        }
    }

    func renderIsEqual() -> ObjCIR.Method {
        return ObjCIR.method("- (BOOL)isEqual:(id)anObject") {
            [
                ObjCIR.ifStmt("self == anObject") { ["return YES;"] },
                self.isBaseClass ? "" : ObjCIR.ifStmt("[super isEqual:anObject] == NO") { ["return NO;"] },
                ObjCIR.ifStmt("[anObject isKindOfClass:[\(self.className) class]] == NO") { ["return NO;"] },
                "return [self isEqualTo\(self.rootSchema.name.snakeCaseToCamelCase()):anObject];"
            ].filter { $0 != "" }
        }
    }

    func renderInitWithDictionary() -> ObjCIR.Method {
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
                return [
                    "NSArray *items = \(rawObjectName);",
                    "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items.count];",
                    ObjCIR.forStmt("id obj in items") { [
                        ObjCIR.ifStmt("[obj isEqual:[NSNull null]] == NO") { [
                                "id \(currentTmp) = nil;",
                            renderPropertyInit(currentTmp, "obj", schema: itemType, firstName: firstName, counter: counter + 1).joined(separator: "\n"),
                            ObjCIR.ifStmt("\(currentTmp) != nil") {[
                                "[\(currentResult) addObject:\(currentTmp)];"
                            ]}
                        ]}
                    ]},
                    "\(propertyToAssign) = \(currentResult);"
                ]
            case .Map(valueType: .some(let valueType)):
                let currentResult = "result\(counter)"
                return [
                    "NSDictionary *items = \(rawObjectName);",
                    "NSMutableDictionary *\(currentResult) = [NSMutableDictionary dictionaryWithCapacity:items.count];",
                    ObjCIR.stmt(
                        ObjCIR.msg("items",
                               ("enumerateKeysAndObjectsUsingBlock",
                                ObjCIR.block(["NSString *  _Nonnull key",
                                              "id  _Nonnull obj",
                                              "__unused BOOL * _Nonnull stop"]) {
                                    [
                                        ObjCIR.ifStmt("obj != nil && [obj isEqual:[NSNull null]] == NO") {
                                            renderPropertyInit("\(currentResult)[key]", "obj", schema: valueType, firstName: firstName, counter: counter + 1)
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
                return ["\(propertyToAssign) = [[NSValueTransformer valueTransformerForName:\(DateValueTransformerKey)] transformedValue:\(rawObjectName)];"]
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

        return ObjCIR.method("- (instancetype)initWithDictionary:(NSDictionary *)modelDictionary") {
            let x: [String] = self.properties.map{ (name, schema) in
                ObjCIR.ifStmt("[key isEqualToString:\(name.objcLiteral())]") {
                    [
                        "id value = valueOrNil(modelDictionary, \(name.objcLiteral()));",
                        ObjCIR.ifStmt("value != nil") {
                            renderPropertyInit("_\(name.snakeCaseToPropertyName())", "value", schema: schema, firstName: name)
                        },
                        "_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: name, className: className)) = 1;"
                    ]
                }
            }

            return [
                "NSParameterAssert(modelDictionary);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                                   "if (!(self = [super initWithDictionary:modelDictionary])) { return self; }",
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
                    ["[self PIModelDidInitialize:PIModelInitTypeDefault];"]
                },
                "return self;"
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

    func renderInitWithBuilderWithInitType() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithBuilder:(\(builderClassName) *)builder initType:(PIModelInitType)initType") {
            [
                "NSParameterAssert(builder);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                                   ObjCIR.ifStmt("!(self = [super initWithBuilder:builder initType:initType])") { ["return self;"] },
                self.properties.map { (name, schema) in
                    "_\(name.snakeCaseToPropertyName()) = builder.\(name.snakeCaseToPropertyName());"
                }.joined(separator: "\n"),
                "_\(self.dirtyPropertiesIVarName) = builder.\(self.dirtyPropertiesIVarName);",
                ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                    ["[self PIModelDidInitialize:initType];"]
                },
                "return self;"
            ]
        }
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

    func renderInitWithCoder() -> ObjCIR.Method {
        func referencedObjectClasses(_ schema:Schema) -> Set<String> {
            switch schema {
            case .Array(itemType: .none):
                return Set(["NSArray"])
            case .Array(itemType: .some(let itemType)):
                return Set(["NSArray"]).union(referencedObjectClasses(itemType))
            case .Map(valueType: .none):
                return Set(["NSDictionary"])
            case .Map(valueType: .some(let valueType)):
                return Set(["NSDictionary"]).union(referencedObjectClasses(valueType))
            case .String(format: .none),
                 .String(format: .some(.Email)),
                 .String(format: .some(.Hostname)),
                 .String(format: .some(.Ipv4)),
                 .String(format: .some(.Ipv6)):
                return Set(["NSString"])
            case .String(format: .some(.DateTime)):
                return Set(["NSDate"])
            case .String(format: .some(.Uri)):
                return Set(["NSURL"])
            case .Integer, .Float, .Boolean, .Enum(_):
                return Set(["NSNumber"])
            case .Object(let objSchemaRoot):
                return Set([objSchemaRoot.className(with: self.params)])
            case .Reference(with: let fn):
                switch fn() {
                case .some(.Object(let schemaRoot)):
                    return referencedObjectClasses(.Object(schemaRoot))
                default:
                    fatalError("Bad reference found in schema for class: \(self.className)")
                }
            case .OneOf(types: let schemaTypes):
                return schemaTypes.map(referencedObjectClasses).reduce(Set(), { s1, s2 in s1.union(s2) })
            }
        }

        func formatParam(_ param: String, _ schema: Schema) -> String {
            let propIVarName = "_\(param.snakeCaseToPropertyName())"
            return "\(propIVarName) = " + { switch schema {
            case .Enum(_):
                return "[aDecoder decodeIntegerForKey:\(param.objcLiteral())];"
            case .Boolean:
                return "[aDecoder decodeBoolForKey:\(param.objcLiteral())];"
            case .Float:
                return "[aDecoder decodeDoubleForKey:\(param.objcLiteral())];"
            case .Integer:
                return "[aDecoder decodeIntegerForKey:\(param.objcLiteral())];"
            case .String(_), .Map(_), .Array(_), .OneOf(_), .Reference(_), .Object(_):
                let refObjectClasses = referencedObjectClasses(schema).map { "[\($0) class]" }
                let refObjectClassesString = refObjectClasses.count == 1 ? refObjectClasses.joined(separator: ",") : "[NSSet setWithArray:\(refObjectClasses.objcLiteral())]"
                if refObjectClasses.count == 0 { fatalError("Can't determine class for decode for \(schema)") }
                if refObjectClasses.count == 1 {
                    return "[aDecoder decodeObjectOfClass:\(refObjectClassesString) forKey:\(param.objcLiteral())];"
                } else {
                    return "[aDecoder decodeObjectOfClasses:\(refObjectClassesString) forKey:\(param.objcLiteral())];"
                }
            } }()
        }

        return ObjCIR.method("- (instancetype)initWithCoder:(NSCoder *)aDecoder") {
            [
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                                   "if (!(self = [super initWithCoder:aDecoder])) { return self; }",
                self.properties.map(formatParam).joined(separator: "\n"),
                self.properties.map { (param, _) -> String in
                    "_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) = [aDecoder decodeIntForKey:\((param + "_dirty_property").objcLiteral())];"
                }.joined(separator: "\n"),
                ObjCIR.ifStmt("[self class] == [\(self.className) class]") {
                    ["[self PIModelDidInitialize:PIModelInitTypeDefault];"]
                },
                "return self;"
            ]
        }
    }


    func renderEncodeWithCoder() -> ObjCIR.Method {

        func formatParam(_ param: String, _ schema: Schema) -> String {
            let propGetter = "self.\(param.snakeCaseToPropertyName())"
            switch schema {
            case .Enum(_):
                return "[aCoder encodeInteger:\(propGetter) forKey:\(param.objcLiteral())];"
            case .Boolean:
                return "[aCoder encodeBool:\(propGetter) forKey:\(param.objcLiteral())];"
            case .Float:
                return "[aCoder encodeDouble:\(propGetter) forKey:\(param.objcLiteral())];"
            case .Integer:
                return "[aCoder encodeInteger:\(propGetter) forKey:\(param.objcLiteral())];"
            case .String(_), .Map(_), .Array(_), .OneOf(_), .Reference(_), .Object(_):
                return "[aCoder encodeObject:\(propGetter) forKey:\(param.objcLiteral())];"
            }
        }

        return ObjCIR.method("- (void)encodeWithCoder:(NSCoder *)aCoder") {
            [
                self.isBaseClass ? "" : "[super encodeWithCoder:aCoder];",
                self.properties.map(formatParam).joined(separator: "\n"),
                self.properties.map { (param, _) -> String in
                    "[aCoder encodeInt:_\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) forKey:\((param + "_dirty_property").objcLiteral())];"}.joined(separator: "\n")
            ].filter { $0 != "" }
        }
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

    func renderSupportsSecureCoding() -> ObjCIR.Method {
        return ObjCIR.method("+ (BOOL)supportsSecureCoding") { ["return YES;"] }
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


    // MARK: Builder methods

    func renderBuilderInitWithModel() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithModel:(\(self.className) *)modelObject") {
            [
                "NSParameterAssert(modelObject);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                                   "if (!(self = [super initWithModel:modelObject])) { return self; }",
                "struct \(self.dirtyPropertyOptionName) \(dirtyPropertiesIVarName) = modelObject.\(dirtyPropertiesIVarName);",
                self.properties.map({ (param, schema) -> String in
                    ObjCIR.ifStmt("\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                        ["_\(param.snakeCaseToPropertyName()) = modelObject.\(param.snakeCaseToPropertyName());"]
                    }
                }).joined(separator: "\n"),
                "_\(self.dirtyPropertiesIVarName) = \(self.dirtyPropertiesIVarName);",
                "return self;"
            ]
        }
    }

    func renderBuilderMergeWithModel() -> ObjCIR.Method {
        func formatParam(_ param: String, _ schema: Schema) -> String {
            return ObjCIR.ifStmt("modelObject.\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                func loop(_ schema: Schema) -> [String] {
                switch schema {
                case .Object(_):
                    return [
                        "id value = modelObject.\(param.snakeCaseToPropertyName());",
                        ObjCIR.ifElseStmt("value != nil") {[
                            ObjCIR.ifElseStmt("builder.\(param.snakeCaseToPropertyName())") {[
                                "builder.\(param.snakeCaseToPropertyName()) = [builder.\(param.snakeCaseToPropertyName()) mergeWithModel:value initType:PIModelInitTypeFromSubmerge];"
                            ]} {[
                                "builder.\(param.snakeCaseToPropertyName()) = value;"
                            ]}
                        ]} {[
                            "builder.\(param.snakeCaseToPropertyName()) = nil;"
                        ]}
                    ]
                case .Reference(with: let fn):
                    switch fn() {
                    case .some(.Object(let objSchema)):
                        return loop(.Object(objSchema))
                    default:
                        fatalError("Error identifying reference for \(param) in \(schema)")
                    }
                default:
                    return ["builder.\(param.snakeCaseToPropertyName()) = modelObject.\(param.snakeCaseToPropertyName());"]
                    }
                }
                return loop(schema)
            }
        }

        return ObjCIR.method("- (void)mergeWithModel:(\(self.className) *)modelObject") {
            [
                "NSParameterAssert(modelObject);",
                self.isBaseClass ? "" : "[super mergeWithModel:modelObject];",
                "\(self.builderClassName) *builder = self;",
                self.properties.map(formatParam).joined(separator: "\n")
            ].filter { $0 != "" }
        }
    }

    fileprivate func objcClassFromSchema(_ param: String, _ schema:Schema) -> String {
        switch schema {
        case .Array(itemType: .none):
            return "NSArray *"
        case .Array(itemType: .some(let itemType)):
            return "NSArray<\(objcClassFromSchema(param, itemType))> *"
        case .Map(valueType: .none):
            return "NSDictionary *"
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
            func inheritanceChain(schema: Schema?) -> [SchemaObjectRoot] {
                switch schema {
                case .none:
                    return []
                case .some(.Object(let root)):
                    return [root] + inheritanceChain(schema: root.extends.flatMap{ $0() })
                case .some(.Reference(with: let fn)):
                    return inheritanceChain(schema: fn())
                default:
                    fatalError("Unimplemented one of: \(schema)")
                }
            }

            let chains: [[SchemaObjectRoot]] = schemaTypes
                .map(inheritanceChain)
                .map { $0.reversed() }

            let commonParent = chains[0].enumerated().filter{ idx, val in
                chains.filter { $0[idx] == val }.count == chains.count
                }.last.map{$0.1}

            return "__kindof \((commonParent ?? RootNSObject).className(with: self.params)) *"
        }
    }

    func renderBuilderPropertySetters() -> [ObjCIR.Method] {
        return self.properties.map({ (param, schema) -> ObjCIR.Method in
            ObjCIR.method("- (void)set\(param.snakeCaseToCapitalizedPropertyName()):(\(objcClassFromSchema(param, schema)))\(param.snakeCaseToPropertyName())") {
                [
                    "_\(param.snakeCaseToPropertyName()) = \(param.snakeCaseToPropertyName());",
                    "_\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) = 1;"
                ]
            }
        })
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
            "NSSecureCoding" : [self.renderSupportsSecureCoding(), self.renderInitWithCoder(), self.renderEncodeWithCoder()],
            "NSCopying": [ObjCIR.method("- (id)copyWithZone:(NSZone *)zone") { ["return self;"] }],
            "PIModelProtocol": []
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
                    (self.isBaseClass ? .Public : .Private, self.renderInitWithDictionary()),
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
                    (.Public, self.renderBuilderMergeWithModel()),
                    ] + self.renderBuilderPropertySetters().map { (.Private, $0) },
                properties: properties.map { param, schema in (param, objcClassFromSchema(param, schema), schema, .ReadWrite) },
                protocols: [:]),
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_END")
        ]
    }
}
