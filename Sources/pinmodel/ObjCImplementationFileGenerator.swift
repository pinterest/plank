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
    let dirtyPropertyOptionName: String
    let generationParameters: GenerationParameters
    let parentDescriptor: ObjectSchemaObjectProperty?
    let dirtyPropertiesIVarName: String
    let parentDirtyPropertiesIVarName: String?
    let schemaLoader: SchemaLoader


    required init(descriptor: ObjectSchemaObjectProperty, generatorParameters: GenerationParameters, parentDescriptor: ObjectSchemaObjectProperty?, schemaLoader: SchemaLoader) {
        self.objectDescriptor = descriptor
        if let classPrefix = generatorParameters[GenerationParameterType.classPrefix] as String? {
            self.className = "\(classPrefix)\(self.objectDescriptor.name.snakeCaseToCamelCase())"
        } else {
            self.className = self.objectDescriptor.name.snakeCaseToCamelCase()
        }
        self.builderClassName = "\(self.className)Builder"
        self.dirtyPropertyOptionName = "\(self.className)DirtyProperties"
        self.generationParameters = generatorParameters
        self.parentDescriptor = parentDescriptor
        self.dirtyPropertiesIVarName = parentDescriptor == nil ? "baseDirtyProperties" : "dirtyProperties"
        self.schemaLoader = schemaLoader

        if let _ = parentDescriptor {
            self.parentDirtyPropertiesIVarName = "baseDirtyProperties"
        } else {
            self.parentDirtyPropertiesIVarName = nil
        }
    }

    func fileName() -> String {
        return "\(self.className).m"
    }

    func isBaseClass() -> Bool {
        return self.parentDescriptor == nil
    }

    func baseClass() -> ObjectSchemaObjectProperty? {
        var baseClass = self.parentDescriptor
        while let parentClassSchema = baseClass?.extends as ObjectSchemaPointerProperty? {
            baseClass = schemaLoader.loadSchema(parentClassSchema.ref) as? ObjectSchemaObjectProperty
        }
        return baseClass
    }

    func baseClassName() -> String {
        if let parentSchema = self.baseClass() as ObjectSchemaObjectProperty? {
            return ObjectiveCInterfaceFileDescriptor(
                descriptor: parentSchema,
                generatorParameters: self.generationParameters,
                parentDescriptor: nil,
                schemaLoader: self.schemaLoader).className
        }
        return NSObject.pin_className()
    }

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
                parentDescriptor: nil,
                schemaLoader: self.schemaLoader).className
        }
        return NSStringFromClass(NSObject.self)
    }

    func pragmaMark(_ pragmaName: String) -> String {
        return "#pragma mark - \(pragmaName)"
    }

    func renderUtilityFunctions() -> String {
        return self.renderStringEnumUtilityMethods()
    }

    func renderImports() -> String {
        let referencedImportStatements: [String] = self.objectDescriptor.referencedClasses.flatMap({ (propDescriptor: ObjectSchemaPointerProperty) -> String? in
            let prop = PropertyFactory.propertyForDescriptor(propDescriptor, className: self.className, schemaLoader: self.schemaLoader)
            if prop.objectiveCStringForJSONType() == self.className {
                return nil
            }
            return "#import \"\(prop.objectiveCStringForJSONType()).h\""
        })

        var importStatements = ["#import \"\(self.className).h\"",
                                "#import \"PINModelRuntime.h\""
        ]
        importStatements.append(contentsOf: referencedImportStatements)
        return importStatements.sorted().joined(separator: "\n")
    }

    func renderPrivateInterface() -> String {
        var modelLines = [
            "@interface \(self.className) ()",
            "@property (nonatomic, assign) struct \(self.dirtyPropertyOptionName) \(self.dirtyPropertiesIVarName);",
            "@end"
        ];

        var builderLines = [
            "@interface \(self.builderClassName) ()",
            "@property (nonatomic, assign) struct \(self.dirtyPropertyOptionName) \(self.dirtyPropertiesIVarName);",
            "@end"
        ]

        if let parentDirtyPropertiesIVarName = parentDirtyPropertiesIVarName, !self.isBaseClass() {
            modelLines.insert("@property (nonatomic, assign) struct \(self.parentClassName())DirtyProperties \(parentDirtyPropertiesIVarName);", at: 1)
            builderLines.insert("@property (nonatomic, assign) struct \(self.parentClassName())DirtyProperties \(parentDirtyPropertiesIVarName);", at: 1)
        }

        return [modelLines.joined(separator: "\n"), builderLines.joined(separator: "\n")].joined(separator: "\n\n")
    }

    func renderDirtyPropertyOptions() -> String {
        let optionsLines: [String] = self.classProperties().map { (property) in
            let prop = PropertyFactory.propertyForDescriptor(property, className: self.className, schemaLoader: self.schemaLoader)
            return "    unsigned int \(prop.dirtyPropertyOption()):1;"
        }
        let lines = [
            "struct \(self.className)DirtyProperties {",
            optionsLines.joined(separator: "\n"),
            "};"
        ]
        return lines.joined(separator: "\n")
    }

    func renderModelObjectWithDictionary() -> String {
        return [
            "+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary",
            "{",
            "    return [[self alloc] initWithDictionary:dictionary];",
            "}"
        ].joined(separator: "\n")
    }

    func renderClassName() -> String {

        return [
            "+ (NSString *)className",
            "{",
            "    return @\"\(self.className)\";",
            "}"
        ].joined(separator: "\n")
    }

    func renderPolymorphicTypeIdentifier() -> String {
        let typeIdentifier = PropertyFactory.propertyForDescriptor(self.objectDescriptor,
                                                                   className: self.className,
                                                                   schemaLoader: self.schemaLoader).polymorphicTypeIdentifier()
        return [
            "+ (NSString *)polymorphicTypeIdentifier",
            "{",
            "    return @\"\(typeIdentifier)\";",
            "}"
        ].joined(separator: "\n")
    }

    func renderInitWithDictionary() -> String {
        let indentation = "    "
        func renderInitForProperty(_ propertyDescriptor: ObjectSchemaProperty) -> String {
            var lines: [String] = []
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className, schemaLoader: self.schemaLoader)

            if property.propertyRequiresAssignmentLogic() {
                lines = ["id value = valueOrNil(modelDictionary, @\"\(propertyDescriptor.name)\");",
                    "if (value != nil) {"]
                    + property.propertyAssignmentStatementFromDictionary(self.className).map({ indentation + $0 })
                    + ["}"]
            } else {
                lines = property.propertyAssignmentStatementFromDictionary(self.className)
            }

            lines.append(property.dirtyPropertyAssignmentStatement(self.dirtyPropertiesIVarName))
            let result = ["if ([key isEqualToString:@\"\(propertyDescriptor.name)\"]) {"] + lines.map({indentation + $0}) + [ indentation + "return;", "}"]
            return result.map({ indentation + indentation + $0 }).joined(separator: "\n")
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
            "    [modelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {",
            "",
                        propertyLines.joined(separator: "\n\n"),
            "    }];",
            "",
            "    return self;",
            "}"
        ]
        if self.isBaseClass() == false {
            lines.insert(indentation + "[self \(self.baseClassName())DidInitialize:PIModelInitTypeDefault];\n", at: lines.count - 2)
        }
        return lines.joined(separator: "\n")
    }

    func renderCopyWithBlock() -> String {
        let lines = [
            "- (instancetype)copyWithBlock:(__attribute__((noescape)) void (^)(id builder))block",
            "{",
            "    NSParameterAssert(block);",
            "    \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
            "    block(builder);",
            "    return [builder build];",
            "}"
        ]
        return lines.joined(separator: "\n")
    }

    func renderDesignatedInit() -> String {
        let lines = [
            "- (instancetype)init",
            "{",
            "   self = [self initWithDictionary:@{}];",
            "   return self;",
            "}"
        ]
        return lines.joined(separator: "\n")
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

        var lines: [String] = []
        if self.isBaseClass() {
            lines = [
                "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder",
                "{",
                "    NSParameterAssert(builder);",
                superInitCall,
                propertyLines.map({ indentation + $0 }).joined(separator: "\n"),
                "    _\(self.dirtyPropertiesIVarName) = builder.\(self.dirtyPropertiesIVarName);",
                "    return self;",
                "}"
            ]
        } else {
            lines = [
                "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder",
                "{",
                "    return [self initWithBuilder:builder initType:PIModelInitTypeDefault];",
                "}",
                "",
                "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder initType:(PIModelInitType)initType",
                "{",
                "    NSParameterAssert(builder);",
                superInitCall,
                propertyLines.map({ indentation + $0 }).joined(separator: "\n"),
                "    _\(self.dirtyPropertiesIVarName) = builder.\(self.dirtyPropertiesIVarName);",
                "    [self \(self.baseClassName())DidInitialize:initType];",
                "    return self;",
                "}"
            ]
        }
        return lines.joined(separator: "\n")
    }

    func renderBuilderInitWithModelObject() -> String {
        let indentation = "    "

        func renderInitForProperty(_ propertyDescriptor: ObjectSchemaProperty) -> String {
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className, schemaLoader: self.schemaLoader)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()
            let lines: [String] = [
                "if (\(self.dirtyPropertiesIVarName).\(property.dirtyPropertyOption())) {",
                "    _\(formattedPropName) = modelObject.\(formattedPropName);",
                "}"
            ]
            return lines.map({ indentation + $0 }).joined(separator: "\n")
        }
        let propertyLines: [String] = self.classProperties().map({ renderInitForProperty($0)})

        var superInitCall = indentation + "if (!(self = [super initWithModel:modelObject])) { return self; }"
        if self.isBaseClass() {
            superInitCall = indentation + "if (!(self = [super init])) { return self; }"
        }
        let lines = [
            "- (instancetype)initWithModel:(\(self.className) *)modelObject",
            "{",
            "    NSParameterAssert(modelObject);",
            superInitCall,
            "",
            "    struct \(self.dirtyPropertyOptionName) \(self.dirtyPropertiesIVarName) = modelObject.\(self.dirtyPropertiesIVarName);",
            "",
            propertyLines.joined(separator: "\n"),
            "",
            "    _\(self.dirtyPropertiesIVarName) = \(self.dirtyPropertiesIVarName);",
            "",
            "    return self;",
            "}"
        ]
        return lines.joined(separator: "\n")
    }

    func renderSupportsSecureCoding() -> String {
        return [
            "+ (BOOL)supportsSecureCoding",
            "{",
            "    return YES;",
            "}"
        ].joined(separator: "\n")
    }

    func renderInitWithCoder() -> String {
        let indentation = "    "
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            let prop = PropertyFactory.propertyForDescriptor(property, className: self.className, schemaLoader: self.schemaLoader)
            let decodeStmt = prop.renderDecodeWithCoderStatement()
            return "_\(formattedPropName) = \(decodeStmt);"
        }
        // Done in one line here because Swift complains about complexity when placed in array
        let dirtyPropertyLines = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            return PropertyFactory.propertyForDescriptor(property, className: self.className, schemaLoader: self.schemaLoader).renderDecodeWithCoderStatementForDirtyProperties(self.dirtyPropertiesIVarName)
        }.map({ indentation + $0 }).joined(separator: "\n\n") + "\n"

        var superInitCall = indentation + "if (!(self = [super initWithCoder:aDecoder])) { return self; }"
        if self.isBaseClass() {
            superInitCall = indentation + "if (!(self = [super init])) { return self; }"
        }
        var lines = [
            "- (instancetype)initWithCoder:(NSCoder *)aDecoder",
            "{",
            superInitCall + "\n",
            propertyLines.map({ indentation + $0 }).joined(separator: "\n\n") + "\n",
            "",
            dirtyPropertyLines,
            "    return self;",
            "}"
        ]
        if !self.isBaseClass() {
            lines.insert(indentation + "[self \(self.baseClassName())DidInitialize:PIModelInitTypeDefault];\n", at: lines.count - 2)
        }
        return lines.joined(separator: "\n")
    }

    func renderEncodeWithCoder() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            return PropertyFactory.propertyForDescriptor(property, className: self.className, schemaLoader: self.schemaLoader).renderEncodeWithCoderStatement() + ";"
        }
        let dirtyPropertyLines = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            return PropertyFactory.propertyForDescriptor(property, className: self.className, schemaLoader: self.schemaLoader).renderEncodeWithCoderStatementForDirtyProperties(self.dirtyPropertiesIVarName)
        }
        let indentation = "    "
        var encodeWithCoderLines = [
            "- (void)encodeWithCoder:(NSCoder *)aCoder",
            "{",
            propertyLines.map({ indentation + $0 }).joined(separator: "\n\n") + "\n",
            dirtyPropertyLines.map({ indentation + $0 }).joined(separator: "\n\n"),
            "}"
        ]

        if !self.isBaseClass() {
            encodeWithCoderLines.insert(indentation + "[super encodeWithCoder:aCoder];", at: 2)
        }

        return encodeWithCoderLines.joined(separator: "\n")
    }

    func renderMergeWithModel() -> String {
        let indentation = "    "

        func renderMergeForProperty(_ propertyDescriptor: ObjectSchemaProperty, isParentProperty: Bool) -> String {
            var lines: [String] = []
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className, schemaLoader: self.schemaLoader)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()

            if propertyDescriptor.isModelProperty {
                lines = ["id value = modelObject.\(formattedPropName);",
                    "if (value != nil) {",
                    indentation + "if (builder.\(formattedPropName) != nil) {",
                    indentation + indentation + "builder.\(formattedPropName) = [builder.\(formattedPropName) mergeWithModel:value initType:PIModelInitTypeFromSubmerge];",
                    indentation + "} else {",
                    indentation + indentation + "builder.\(formattedPropName) = value;",
                    indentation + "}",
                    "} else {",
                    indentation + "builder.\(formattedPropName) = nil;",
                    "}"]
            } else if propertyDescriptor.name == "additional_local_non_API_properties" {
                lines = ["if (builder.\(formattedPropName)) {",
                    indentation + "NSMutableDictionary *mutableProperties = [[NSMutableDictionary alloc] initWithDictionary:builder.\(formattedPropName)];",
                    indentation + "[mutableProperties addEntriesFromDictionary:modelObject.\(formattedPropName)];",
                    indentation + "builder.\(formattedPropName) = mutableProperties;",
                    "} else {",
                    indentation + "builder.\(formattedPropName) = modelObject.\(formattedPropName);",
                    "}"
                ]
            } else {
                lines = ["builder.\(formattedPropName) = modelObject.\(formattedPropName);"]
            }
            var parentOrChildDirtyPropertiesString = self.dirtyPropertiesIVarName
            var parentOrChildDirtyPropertyNameString = property.dirtyPropertyOption()

            if let parentDirtyPropertiesIVarName = self.parentDirtyPropertiesIVarName, isParentProperty {
                parentOrChildDirtyPropertiesString = parentDirtyPropertiesIVarName
                parentOrChildDirtyPropertyNameString = "\(self.parentClassName())DirtyProperty\(propertyDescriptor.name.snakeCaseToCapitalizedPropertyName())"
            }

            let result = ["if (modelObject.\(parentOrChildDirtyPropertiesString).\(parentOrChildDirtyPropertyNameString)) {"] + lines.map({indentation + $0}) + ["}"]
            return result.map({ indentation + $0 }).joined(separator: "\n")
        }

        let parentPropertyLines = self.parentClassProperties().sorted(by: {$0.name < $1.name}).map({ renderMergeForProperty($0, isParentProperty: true) })
        let propertyLines = self.classProperties().sorted(by: {$0.name < $1.name}).map({ renderMergeForProperty($0, isParentProperty: false)})

        var lines = [
            "- (instancetype)mergeWithModel:(\(self.className) *)modelObject {",
            "    return [self mergeWithModel:modelObject initType:PIModelInitTypeFromMerge];",
            "}",
            "",
            "- (instancetype)mergeWithModel:(\(self.className) *)modelObject initType:(PIModelInitType)initType",
            "{",
            "    NSParameterAssert(modelObject);",
            "    \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",
            "",
            parentPropertyLines.joined(separator: "\n\n"),
            propertyLines.joined(separator: "\n\n"),
            "",
            "}"
        ]
        if self.isBaseClass() {
            lines.insert(indentation + "return [builder build];", at: lines.count - 1)
        } else {
            lines.insert(indentation + "return [[\(self.className) alloc] initWithBuilder:builder initType:initType];", at: lines.count - 1)
        }
        return lines.joined(separator: "\n")
    }

    func renderStringEnumUtilityMethods() -> String {
        let enumProperties = self.objectDescriptor.properties.filter({ PropertyFactory.propertyForDescriptor($0, className: self.className, schemaLoader: self.schemaLoader).isEnumPropertyType() && $0.jsonType == JSONType.String })

        let indentation = "    "

        let enumMethods: [String] = enumProperties.map { (prop: ObjectSchemaProperty) -> String in
            assert(prop.defaultValue != nil, "We need a default value for code generation of this string enum.")
            let objcProp = PropertyFactory.propertyForDescriptor(prop, className: self.className, schemaLoader: self.schemaLoader)
            let defaultEnumVal = prop.enumValues.filter { ($0.defaultValue as! String) == prop.defaultValue as! String }[0]
            let defaultEnumName = objcProp.enumPropertyTypeName() + (defaultEnumVal.description).snakeCaseToCamelCase()
            // String to Enum
            let stringToEnumConditionals: [String] = prop.enumValues.map {
                let description = $0.description
                let enumValueName = objcProp.enumPropertyTypeName() + description.snakeCaseToCamelCase()
                return ["if ([str isEqualToString:@\"\($0.defaultValue as! String)\"]) {",
                        indentation + "return \(enumValueName);",
                        "}"
                    ].map { indentation + $0 }.joined(separator: "\n")
            }

            let stringToEnumLines = [
                "extern \(objcProp.enumPropertyTypeName()) \(objcProp.enumPropertyTypeName())FromString(NSString *str)",
                "{",
                stringToEnumConditionals.joined(separator: "\n"),
                indentation + "return \(defaultEnumName);",
                "}"
            ].joined(separator: "\n")

            // Enum to String
            let enumToStringConditionals: [String] = prop.enumValues.map {
                let description = $0.description
                let defaultVal = $0.defaultValue as! String
                let enumValueName = objcProp.enumPropertyTypeName() + description.snakeCaseToCamelCase()
                return ["if (enumType == \(enumValueName)) {",
                    indentation +  "return @\"\(defaultVal)\";",
                    "}"
                    ].map { indentation + $0 }.joined(separator: "\n")
            }


            let enumToStringLines = [
                "extern NSString * \(objcProp.enumPropertyTypeName())ToString(\(objcProp.enumPropertyTypeName()) enumType)",
                "{",
                enumToStringConditionals.joined(separator: "\n"),
                indentation + "return @\"\(prop.defaultValue as! String)\";",
                "}"
            ].joined(separator: "\n")
            return [stringToEnumLines, enumToStringLines].joined(separator: "\n\n")
        }
        return enumMethods.joined(separator: "\n\n")
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

    func renderPropertyNames(_ methodName: String, includeProperty: (ObjectSchemaProperty) -> Bool) -> String {
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
                    .map { String(repeating: String((" " as Character)), count: returnLine.characters.count) + "@\"\($0.snakeCaseToPropertyName())\""}
                    .joined(separator: ",\n"),
                String(repeating: String((" " as Character)), count: returnLine.characters.count) + "];"
            ]
        }
        lines.insert("- (NSArray<NSString *> *)" + methodName, at: 0)
        lines.insert("{", at: 1)
        lines.insert("}", at: lines.count)
        return lines.joined(separator: "\n")
    }

    func renderCopyWithZone() -> String {
        return [
            "- (id)copyWithZone:(NSZone *)zone",
            "{",
            "    return self;",
            "}"
        ].joined(separator: "\n")
    }

    func renderBuildMethod() -> String {
        let lines = [
            "- (\(self.className) *)build",
            "{",
            "    return [[\(self.className) alloc] initWithBuilder:self];",
            "}"
        ]
        return lines.joined(separator: "\n")
    }

    func renderBuilderSetters() -> String {
        func renderBuilderSetterForProperty(_ propertyDescriptor: ObjectSchemaProperty) -> String {
            let indentation = "    "
            let property = PropertyFactory.propertyForDescriptor(propertyDescriptor, className: self.className, schemaLoader: self.schemaLoader)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()
            let capitalizedPropertyName = propertyDescriptor.name.snakeCaseToCapitalizedPropertyName()
            let type = property.isScalarType() ? property.objectiveCStringForJSONType() : property.objectiveCStringForJSONType() + " *"

            let lines = [
                "- (void)set\(capitalizedPropertyName):(\(type))\(formattedPropName)",
                "{",
                "\(indentation)_\(formattedPropName) = \(formattedPropName);",
                "\(indentation)\(property.dirtyPropertyAssignmentStatement(self.dirtyPropertiesIVarName))",
                "}"
            ]
            return lines.joined(separator: "\n")
        }

        return self.classProperties().map({ renderBuilderSetterForProperty($0) }).joined(separator: "\n\n")
    }

    func renderBuilderImplementation() -> String {
        var lines = [
            "@implementation \(self.builderClassName)",
        ];

        if let parentDirtyPropertyName = self.parentDirtyPropertiesIVarName , !self.isBaseClass() {
            lines.append("@dynamic \(parentDirtyPropertyName);")
        }

        lines.append(
        contentsOf: [
            self.renderBuilderInitWithModelObject(),
            self.renderBuildMethod(),
            self.renderBuilderSetters(),
            "@end"
        ])
        return lines.joined(separator: "\n\n")
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
                self.renderModelPropertyNames(),
                self.renderModelArrayPropertyNames(),
                self.renderModelDictionaryPropertyNames(),
                self.pragmaMark("NSCopying implementation"),
                self.renderCopyWithZone(),
                "@end"
            ].filter { "" != $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            return lines.joined(separator: "\n\n")

        }

        let lines = [
            "@implementation \(self.className)",
            "@dynamic \(self.parentDirtyPropertiesIVarName!);",
            self.renderClassName(),
            self.renderPolymorphicTypeIdentifier(),
            self.renderInitWithDictionary(),
            self.renderInitWithBuilder(),
            self.pragmaMark("NSSecureCoding implementation"),
            self.renderInitWithCoder(),
            self.renderEncodeWithCoder(),
            self.pragmaMark("Mutation helper methods"),
            self.renderCopyWithBlock(),
            self.renderMergeWithModel(),
            self.renderModelPropertyNames(),
            self.renderModelArrayPropertyNames(),
            self.renderModelDictionaryPropertyNames(),
            "@end"
        ].filter { "" != $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        return lines.joined(separator: "\n\n")
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
                ].filter { "" != $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            return lines.joined(separator: "\n\n")
        }

        let lines = [
            self.renderCommentHeader(),
            self.renderImports(),
            self.renderDirtyPropertyOptions(),
            self.renderPrivateInterface(),
            self.renderUtilityFunctions(),
            self.renderImplementation(),
            self.renderBuilderImplementation()
        ].filter { "" != $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        return lines.joined(separator: "\n\n")
    }
}
