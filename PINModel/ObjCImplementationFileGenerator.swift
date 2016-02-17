//
//  ObjCImplementationFileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

class ObjectiveCImplementationFileDescriptor: FileGenerator {
    let objectDescriptor: ObjectSchemaObjectProperty
    let className: String
    let builderClassName: String
    let dirtyPropertyOptionName : String
    let generationParameters: GenerationParameters
    let parentDescriptor: ObjectSchemaObjectProperty?


    required init(descriptor: ObjectSchemaObjectProperty, generatorParameters: GenerationParameters, parentDescriptor: ObjectSchemaObjectProperty?) {
        self.objectDescriptor = descriptor
        if let classPrefix = generatorParameters[GenerationParameterType.ClassPrefix] as String? {
            self.className = String(format: "%@%@", arguments: [
                classPrefix,
                self.objectDescriptor.name.snakeCaseToCamelCase()
            ])
        } else {
            self.className = self.objectDescriptor.name.snakeCaseToCamelCase()
        }
        self.builderClassName = "\(self.className)Builder"
        self.dirtyPropertyOptionName = "\(self.className)DirtyProperties"
        self.generationParameters = generatorParameters
        self.parentDescriptor = parentDescriptor
    }

    func fileName() -> String {
        return "\(self.className).m"
    }

    func isBaseClass() -> Bool {
        return self.parentDescriptor == nil
    }

    //TODO make this "lazy"
    func classProperties() -> [ObjectSchemaProperty] {
        if let baseClass = self.parentDescriptor as ObjectSchemaObjectProperty? {
            let baseProperties = Set(baseClass.properties.map({ $0.name }))
            return self.objectDescriptor.properties.filter({ !baseProperties.contains($0.name) })
        }
        return self.objectDescriptor.properties
    }

    func parentClassProperties() -> [ObjectSchemaProperty] {
        if let baseClass = self.parentDescriptor as ObjectSchemaObjectProperty? {
            return baseClass.properties
        }
        return []
    }

    func parentClassName() -> String {
        if let parentSchema = self.parentDescriptor as ObjectSchemaObjectProperty? {
            return ObjectiveCInterfaceFileDescriptor(
                descriptor: parentSchema,
                generatorParameters: self.generationParameters,
                parentDescriptor: nil).className
        }
        return NSStringFromClass(NSObject)
    }

    func pragmaMark(pragmaName: String) -> String {
        return "#pragma mark - \(pragmaName)"
    }

    func renderUtilityFunctions() -> String {
        return self.renderStringEnumUtilityMethods()
    }

    func renderImports() -> String {
        let referencedImportStatements: [String] = self.objectDescriptor.referencedClasses.flatMap({ (propDescriptor: ObjectSchemaPointerProperty) -> String? in
            let prop = PropertyFactory.propertyForDescriptor(propDescriptor, className: self.className)
            if prop.objectiveCStringForJSONType() == self.className {
                return nil
            }
            return "#import \"\(prop.objectiveCStringForJSONType()).h\""
        })

        var importStatements = ["#import \"\(self.className).h\"",
                                "#import \"PINModelRuntime.h\""
        ]
        importStatements.appendContentsOf(referencedImportStatements)
        return importStatements.sort().joinWithSeparator("\n")
    }

    func renderPrivateInterface() -> String {
        let modelLines = [
            "@interface \(self.className) ()",
            "@property (nonatomic, assign) \(self.dirtyPropertyOptionName) dirtyProperties;",
            "@end"
        ];

        let builderLines = [
            "@interface \(self.builderClassName) ()",
            "@property (nonatomic, assign) \(self.dirtyPropertyOptionName) dirtyProperties;",
            "@end"
        ]

        return [modelLines.joinWithSeparator("\n"), builderLines.joinWithSeparator("\n")].joinWithSeparator("\n\n")
    }

    func renderDirtyPropertyOptions() -> String {
        var allProperties : [ObjectSchemaProperty] = []
        if let baseClass = self.parentDescriptor as ObjectSchemaObjectProperty? {
            allProperties.appendContentsOf(baseClass.properties)
        }
        allProperties.appendContentsOf(self.classProperties())

        let optionsLines: [String] = allProperties.enumerate().map { (index, property) in
            assert(index < 64, "Only 64 properties are supported")

            let prop = PropertyFactory.propertyForDescriptor(property, className: self.className)
            let one = "1LL"
            return "    \(prop.dirtyPropertyOption()) = \(one) << \(index),"
        }
        let lines = [
            "typedef NS_OPTIONS(int64_t, \(self.className)DirtyProperties) {",
            optionsLines.joinWithSeparator("\n"),
            "};"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderModelObjectWithDictionary() -> String {
        return [
            "+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary",
            "{",
            "    return [[self alloc] initWithDictionary:dictionary];",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderClassName() -> String {

        return [
            "+ (NSString *)className",
            "{",
            "    return @\"\(self.className)\";",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderPolymorphicTypeIdentifier() -> String {

        return [
            "+ (NSString *)polymorphicTypeIdentifier",
            "{",
            "    return @\"\(self.objectDescriptor.name.lowercaseString)\";",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderDealloc() -> String {
        return [
            "- (void)dealloc",
            "{",
            "    [self \(self.parentClassName())WillDealloc];",
            "}"
            ].joinWithSeparator("\n");
    }

    func renderInitWithDictionary() -> String {
        let indentation = "    "
        func renderInitForProperty(propertyDescriptor: ObjectSchemaProperty) -> String {
            var lines: [String] = []
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className)

            if property.propertyRequiresAssignmentLogic() {
                lines = ["id value = valueOrNil(modelDictionary, @\"\(propertyDescriptor.name)\");",
                    "if (value != nil) {"]
                    + property.propertyAssignmentStatementFromDictionary(self.className).map({ indentation + $0 })
                    + ["}"]
            } else {
                lines = property.propertyAssignmentStatementFromDictionary(self.className)
            }

            lines.append(property.dirtyPropertyAssignmentStatement())
            let result = ["if ([key isEqualToString:@\"\(propertyDescriptor.name)\"]) {"] + lines.map({indentation + $0}) + [ indentation + "return;", "}"]
            return result.map({ indentation + indentation + $0 }).joinWithSeparator("\n")
        }

        let propertyLines: [String] = self.classProperties().map({ renderInitForProperty($0)})

        var superInitCall = "if (!(self = [super initWithDictionary:modelDictionary])) { return self; }"
        if self.isBaseClass() {
            superInitCall = "if (!(self = [super init])) { return self; }"
        }

        var lines = [
            "- (instancetype) __attribute__((annotate(\"oclint:suppress[high npath complexity]\")))",
            "    initWithDictionary:(NSDictionary *)modelDictionary",
            "{",
            "    NSParameterAssert(modelDictionary);",
            indentation + superInitCall,
            "",
            "    [modelDictionary enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {",
            "",
                        propertyLines.joinWithSeparator("\n\n"),
            "    }];",
            "",
            "    return self;",
            "}"
        ]
        if self.isBaseClass() == false {
            lines.insert(indentation + "[self \(self.parentClassName())DidInitialize];\n", atIndex: lines.count - 2)
        }
        return lines.joinWithSeparator("\n")
    }

    func renderCopyWithBlock() -> String {
        let lines = [
            "- (instancetype)copyWithBlock:(void (^)(id builder))block",
            "{",
            "    NSParameterAssert(block);",
            "    \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
            "    block(builder);",
            "    return [builder build];",
            "}"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderDesignatedInit() -> String {
        let lines = [
            "- (instancetype)init",
            "{",
            "   self = [self initWithDictionary:@{}];",
            "   return self;",
            "}"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderInitWithBuilder() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            return "_\(formattedPropName) = builder.\(formattedPropName);"
        }

        let indentation = "    "
        var superInitCall = indentation + "if (!(self = [super initWithBuilder:builder])) { return self; }"
        if self.isBaseClass() {
            superInitCall = indentation + "if (!(self = [super init])) { return self; }"
        }

        var lines : [String] = []
        if self.isBaseClass() {
            lines = [
                "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder",
                "{",
                "    NSParameterAssert(builder);",
                superInitCall,
                propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
                "    _dirtyProperties = builder.dirtyProperties;",
                "    return self;",
                "}"
            ]
        } else {
            lines = [
                "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder",
                "{",
                "    return [self initWithBuilder:builder callDidMerge:NO];",
                "}",
                "",
                "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder callDidMerge:(BOOL)callDidMerge",
                "{",
                "    NSParameterAssert(builder);",
                superInitCall,
                propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
                "    if (callDidMerge) {",
                "        [self \(self.parentClassName())DidMerge];",
                "    } else {",
                "        [self \(self.parentClassName())DidInitialize];",
                "    }",
                "    return self;",
                "}"
            ]
        }
        return lines.joinWithSeparator("\n")
    }

    func renderBuilderInitWithModelObject() -> String {
        let indentation = "    "

        func renderInitForProperty(propertyDescriptor: ObjectSchemaProperty) -> String {
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()
            let lines : [String] = [
                "if (dirtyProperties & \(property.dirtyPropertyOption())) {",
                "    _\(formattedPropName) = modelObject.\(formattedPropName);",
                "}"
            ]
            return lines.map({ indentation + $0 }).joinWithSeparator("\n")
        }
        let propertyLines: [String] = self.classProperties().map({ renderInitForProperty($0)})

        var superInitCall = indentation + "if (!(self = [super initWithModel:modelObject])) { return self; }"
        if self.isBaseClass() {
            superInitCall = indentation + "if (!(self = [super init])) { return self; }"
        }
        var lines = [
            "- (instancetype)initWithModel:(\(self.className) *)modelObject",
            "{",
            "    NSParameterAssert(modelObject);",
            superInitCall,
            "",
            "    \(self.dirtyPropertyOptionName) dirtyProperties = modelObject.dirtyProperties;",
            "",
            propertyLines.joinWithSeparator("\n"),
            "",
            "    return self;",
            "}"
        ]
        if (self.isBaseClass()) {
            lines.insertContentsOf([indentation + "_dirtyProperties = modelObject.dirtyProperties;", "\n"], at: lines.count - 2)
        }
        return lines.joinWithSeparator("\n")
    }

    func renderSupportsSecureCoding() -> String {
        return [
            "+ (BOOL)supportsSecureCoding",
            "{",
            "    return YES;",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderInitWithCoder() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            let prop = PropertyFactory.propertyForDescriptor(property, className: self.className)
            let decodeStmt = prop.renderDecodeWithCoderStatement()
            return "_\(formattedPropName) = \(decodeStmt);"
        }
        let indentation = "    "
        var superInitCall = indentation + "if (!(self = [super initWithCoder:aDecoder])) { return self; }"
        if self.isBaseClass() {
            superInitCall = indentation + "if (!(self = [super init])) { return self; }"
        }
        var lines = [
            "- (instancetype)initWithCoder:(NSCoder *)aDecoder",
            "{",
            superInitCall + "\n",
            propertyLines.map({ indentation + $0 }).joinWithSeparator("\n\n") + "\n",
            "    return self;",
            "}"
        ]
        if self.isBaseClass() {
            lines.insert(indentation + "_dirtyProperties = [aDecoder decodeIntegerForKey:@\"dirty_properties\"];\n", atIndex: lines.count - 2)
        } else {
            lines.insert(indentation + "[self \(self.parentClassName())DidInitialize];\n", atIndex: lines.count - 2)
        }
        return lines.joinWithSeparator("\n")
    }

    func renderEncodeWithCoder() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            return PropertyFactory.propertyForDescriptor(property, className: self.className).renderEncodeWithCoderStatement() + ";"
        }
        let indentation = "    "
        if self.isBaseClass() {
            return [
                "- (void)encodeWithCoder:(NSCoder *)aCoder",
                "{",
                propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
                indentation + "[aCoder encodeInteger:self.dirtyProperties forKey:@\"dirty_properties\"];",
                "}"
            ].joinWithSeparator("\n")
        } else {
            return [
                "- (void)encodeWithCoder:(NSCoder *)aCoder",
                "{",
                indentation + "[super encodeWithCoder:aCoder];",
                propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
                "}"
            ].joinWithSeparator("\n")
        }
    }

    func renderMergeWithModel() -> String {
        let indentation = "    "

        func renderMergeForProperty(propertyDescriptor: ObjectSchemaProperty) -> String {
            var lines: [String] = []
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()

            if propertyDescriptor.isModelProperty {
                lines = ["id value = modelObject.\(formattedPropName);",
                    "if (value != nil) {",
                    indentation + "if (builder.\(formattedPropName) != nil) {",
                    indentation + indentation + "builder.\(formattedPropName) = [builder.\(formattedPropName) mergeWithModel:value callDidMerge:NO];",
                    indentation + "} else {",
                    indentation + indentation + "builder.\(formattedPropName) = value;",
                    indentation + "}",
                    "} else {",
                    indentation + "builder.\(formattedPropName) = nil;",
                    "}"]
            } else {
                lines = ["builder.\(formattedPropName) = modelObject.\(formattedPropName);"]
            }
            let result = ["if (dirtyProperties & \(property.dirtyPropertyOption())) {"] + lines.map({indentation + $0}) + ["}"]
            return result.map({ indentation + $0 }).joinWithSeparator("\n")
        }

        var allProperties: [ObjectSchemaProperty] = self.classProperties() + self.parentClassProperties()
        allProperties.sortInPlace({$0.name < $1.name})
        let propertyLines: [String] = allProperties.map({ renderMergeForProperty($0)})

        var lines = [
            "- (instancetype)mergeWithModel:(\(self.className) *)modelObject {",
            "    return [self mergeWithModel:modelObject callDidMerge:NO];",
            "}",
            "",
            "- (instancetype)mergeWithModel:(\(self.className) *)modelObject callDidMerge:(BOOL)callDidMerge",
            "{",
            "    NSParameterAssert(modelObject);",
            "    \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
            "    \(self.dirtyPropertyOptionName) dirtyProperties = modelObject.dirtyProperties;",
            "",
            propertyLines.joinWithSeparator("\n\n"),
            "",
            "}"
        ]
        if self.isBaseClass() {
            lines.insert(indentation + "return [builder build];", atIndex: lines.count - 1)
        } else {
            lines.insert(indentation + "return [[\(self.className) alloc] initWithBuilder:builder callDidMerge:callDidMerge];", atIndex: lines.count - 1)
        }
        return lines.joinWithSeparator("\n")
    }

    func renderMergeWithDictionary() -> String {
        let indentation = "    "

        func renderMergeForProperty(propertyDescriptor: ObjectSchemaProperty) -> String {
            var lines: [String] = []
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()

            if property.propertyRequiresAssignmentLogic() {
                let propFromDictionary = "valueOrNil(modelDictionary, @\"\(propertyDescriptor.name)\")"
                let propertyLines = property.propertyMergeStatementFromDictionary("builder", className: self.className).map({ indentation + $0 })
                lines = ["id value = \(propFromDictionary);",
                    "if (value != nil) {"] +
                    propertyLines +
                    ["} else {",
                    indentation + "builder.\(formattedPropName) = nil;",
                    "}"]
            } else {
                lines = property.propertyMergeStatementFromDictionary("builder", className: self.className)
            }
            let result = ["if ([key isEqualToString:@\"\(propertyDescriptor.name)\"]) {"] + lines.map({indentation + $0}) + [ indentation + "return;", "}"]
            return result.map({ indentation + indentation + $0 }).joinWithSeparator("\n")
        }

        var allProperties: [ObjectSchemaProperty] = self.classProperties() + self.parentClassProperties()
        allProperties.sortInPlace({$0.name < $1.name})
        let propertyLines: [String] = allProperties.map({ renderMergeForProperty($0)})

        let lines = [
        "- (instancetype)mergeWithDictionary:(NSDictionary *)modelDictionary",
        "{",
        "   NSParameterAssert(modelDictionary);",
        "   \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",

        "   [modelDictionary enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {",
        "        if (obj == [NSNull null]) { return; }",
        "",
            propertyLines.joinWithSeparator("\n\n"),
        "   }];",
        "   return [builder build];",
        "}"
        ]
        return lines.joinWithSeparator("\n")
    }


    func renderStringEnumUtilityMethods() -> String {
        let enumProperties = self.objectDescriptor.properties.filter({ PropertyFactory.propertyForDescriptor($0, className: self.className).isEnumPropertyType() && $0.jsonType == JSONType.String })

        let indentation = "    "

        let enumMethods: [String] = enumProperties.map { (prop: ObjectSchemaProperty) -> String in
            assert(prop.defaultValue != nil, "We need a default value for code generation of this string enum.")
            let objcProp = PropertyFactory.propertyForDescriptor(prop, className: self.className)
            let defaultEnumVal = prop.enumValues.filter { ($0["default"] as! String) == prop.defaultValue as! String }[0]
            let defaultEnumName = objcProp.enumPropertyTypeName() + (defaultEnumVal["description"] as! String).snakeCaseToCamelCase()
            // String to Enum
            let stringToEnumConditionals: [String] = prop.enumValues.map {
                let description = $0["description"] as! String
                let enumValueName = objcProp.enumPropertyTypeName() + description.snakeCaseToCamelCase()
                return ["if ([str isEqualToString:@\"\($0["default"] as! String)\"]) {",
                        indentation + "return \(enumValueName);",
                        "}"
                    ].map { indentation + $0 }.joinWithSeparator("\n")
            }

            let stringToEnumLines = [
                "extern \(objcProp.enumPropertyTypeName()) \(objcProp.enumPropertyTypeName())FromString(NSString *str)",
                "{",
                stringToEnumConditionals.joinWithSeparator("\n"),
                indentation + "return \(defaultEnumName);",
                "}"
            ].joinWithSeparator("\n")

            // Enum to String
            let enumToStringConditionals: [String] = prop.enumValues.map {
                let description = $0["description"] as! String
                let defaultVal = $0["default"] as! String
                let enumValueName = objcProp.enumPropertyTypeName() + description.snakeCaseToCamelCase()
                return ["if (enumType == \(enumValueName)) {",
                    indentation +  "return @\"\(defaultVal)\";",
                    "}"
                    ].map { indentation + $0 }.joinWithSeparator("\n")
            }


            let enumToStringLines = [
                "extern NSString * \(objcProp.enumPropertyTypeName())ToString(\(objcProp.enumPropertyTypeName()) enumType)",
                "{",
                enumToStringConditionals.joinWithSeparator("\n"),
                indentation + "return @\"\(prop.defaultValue as! String)\";",
                "}"
            ].joinWithSeparator("\n")
            return [stringToEnumLines, enumToStringLines].joinWithSeparator("\n\n")
        }
        return enumMethods.joinWithSeparator("\n\n")
    }

    func renderModelPropertyNames() -> String {
        return self.renderPropertyNames("modelPropertyNames", includeProperty: { $0.isModelProperty })
    }
    
    func renderModelArrayPropertyNames() -> String {
        return self.renderPropertyNames("modelArrayPropertyNames",
            includeProperty: { ($0 as? ObjectSchemaArrayProperty)?.items?.isModelProperty ?? false })
    }
    
    func renderModelDictionaryPropertyNames() -> String {
        return self.renderPropertyNames("modelDictionaryPropertyNames",
            includeProperty: { ($0 as? ObjectSchemaObjectProperty)?.additionalProperties?.isModelProperty ?? false })
    }
    
    func renderPropertyNames(methodName: String, includeProperty: (ObjectSchemaProperty) -> Bool) -> String {
        let propertyNames = self.classProperties()
            .filter(includeProperty)
            .map { $0.name }
        
        let indentation = "    "
        
        var lines:Array<String>
        if propertyNames.count == 0 {
            lines = [
                indentation + "return @[];"
            ]
        } else {
            let returnLine = indentation + "return @["
            lines = [
                returnLine,
                propertyNames
                    .map { String(count: returnLine.characters.count, repeatedValue: (" " as Character)) + "@\"\($0.snakeCaseToPropertyName())\""}
                    .joinWithSeparator(",\n"),
                String(count: returnLine.characters.count, repeatedValue: (" " as Character)) + "];"
            ]
        }
        lines.insert("- (NSArray<NSString *> *)" + methodName, atIndex: 0)
        lines.insert("{", atIndex: 1)
        lines.insert("}", atIndex: lines.count)
        return lines.joinWithSeparator("\n")
    }
    
    func renderCopyWithZone() -> String {
        return [
            "- (id)copyWithZone:(NSZone *)zone",
            "{",
            "    return self;",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderBuildMethod() -> String {
        let lines = [
            "- (\(self.className) *)build",
            "{",
            "    return [[\(self.className) alloc] initWithBuilder:self];",
            "}"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderBuilderSetters() -> String {
        func renderBuilderSetterForProperty(propertyDescriptor: ObjectSchemaProperty) -> String {
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()
            let capitalizedPropertyName = propertyDescriptor.name.snakeCaseToCapitalizedPropertyName()
            let type = property.isScalarType() ? property.objectiveCStringForJSONType() : property.objectiveCStringForJSONType() + " *"

            let lines = [
                "- (void)set\(capitalizedPropertyName):(\(type))\(formattedPropName)",
                "{",
                "    _\(formattedPropName) = \(formattedPropName);",
                "    _dirtyProperties |= \(property.dirtyPropertyOption());",
                "}"
            ]
            return lines.joinWithSeparator("\n")
        }

        return self.classProperties().map({ renderBuilderSetterForProperty($0) }).joinWithSeparator("\n\n")
    }

    func renderBuilderImplementation() -> String {
        var lines = [
            "@implementation \(self.builderClassName)",
        ];
        if self.isBaseClass() == false {
            lines.append("@dynamic dirtyProperties;")
        }
        lines.appendContentsOf(
        [
            self.renderBuilderInitWithModelObject(),
            self.renderBuildMethod(),
            self.renderBuilderSetters(),
            "@end"
        ])
        return lines.joinWithSeparator("\n\n")
    }


    func renderImplementation() -> String {

        if self.isBaseClass() {
            let lines = [
                "@implementation \(self.className)",
                self.renderClassName(),
                self.renderPolymorphicTypeIdentifier(),
                self.renderModelObjectWithDictionary(),
                self.renderDesignatedInit(),
                self.renderInitWithDictionary(),
                self.renderInitWithBuilder(),
                self.pragmaMark("NSSecureCoding implementation"),
                self.renderSupportsSecureCoding(),
                self.renderInitWithCoder(),
                self.renderEncodeWithCoder(),
                self.pragmaMark("Mutation helper methods"),
                self.renderCopyWithBlock(),
                self.renderMergeWithModel(),
                self.renderMergeWithDictionary(),
                self.renderModelPropertyNames(),
                self.renderModelArrayPropertyNames(),
                self.renderModelDictionaryPropertyNames(),
                self.pragmaMark("NSCopying implementation"),
                self.renderCopyWithZone(),
                "@end"
            ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
            return lines.joinWithSeparator("\n\n")

        }

        let lines = [
            "@implementation \(self.className)",
            "@dynamic dirtyProperties;",
            self.renderClassName(),
            self.renderPolymorphicTypeIdentifier(),
            self.renderDealloc(),
            self.renderInitWithDictionary(),
            self.renderInitWithBuilder(),
            self.pragmaMark("NSSecureCoding implementation"),
            self.renderInitWithCoder(),
            self.renderEncodeWithCoder(),
            self.pragmaMark("Mutation helper methods"),
            self.renderCopyWithBlock(),
            self.renderMergeWithModel(),
            self.renderMergeWithDictionary(),
            self.renderModelPropertyNames(),
            self.renderModelArrayPropertyNames(),
            self.renderModelDictionaryPropertyNames(),
            "@end"
        ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
        return lines.joinWithSeparator("\n\n")
    }

    func renderFile() -> String {
        if self.isBaseClass() {
            let lines = [
                self.renderCommentHeader(),
                self.renderImports(),
                self.renderPrivateInterface(),
                self.renderUtilityFunctions(),
                self.renderImplementation(),
                self.renderBuilderImplementation()
                ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
            return lines.joinWithSeparator("\n\n")
        }

        let lines = [
            self.renderCommentHeader(),
            self.renderImports(),
            self.renderDirtyPropertyOptions(),
            self.renderPrivateInterface(),
            self.renderUtilityFunctions(),
            self.renderImplementation(),
            self.renderBuilderImplementation()
        ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
        return lines.joinWithSeparator("\n\n")
    }
}
