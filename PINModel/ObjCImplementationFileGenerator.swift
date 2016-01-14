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
        self.generationParameters = generatorParameters
        self.parentDescriptor = parentDescriptor
    }

    func fileName() -> String {
        return "\(self.className).m"
    }

    func isBaseClass() -> Bool {
        return self.parentDescriptor == nil
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
            let prop = ObjectiveCProperty(descriptor: propDescriptor, className: self.className)
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
        let propertyLines: [String] = self.classProperties().map { (propDescriptor: ObjectSchemaProperty) -> String in
            let property = ObjectiveCProperty(descriptor: propDescriptor, className: self.className)

            if property.propertyRequiresAssignmentLogic() {
                let propFromDictionary = "valueOrNil(modelDictionary, @\"\(propDescriptor.name)\")"
                let propertyLines = property.propertyAssignmentStatementFromDictionary(self.className).map({ indentation + indentation + $0 }).joinWithSeparator("\n")
                let lines = [
                    indentation + "value = \(propFromDictionary);",
                    indentation + "if (value != nil) {" ,
                    propertyLines,
                    indentation + "}"
                ]
                return lines.joinWithSeparator("\n")
            }
            return property.propertyAssignmentStatementFromDictionary(self.className).map({ indentation + $0 }).joinWithSeparator("\n")
        }

        let anyPropertiesRequireAssignmentLogic = self.objectDescriptor.properties.map({
            ObjectiveCProperty(descriptor: $0, className: self.className).propertyRequiresAssignmentLogic()}).reduce(false) {
            (sum, nextVal) in
            return sum || nextVal
        }


        var tmpVariableLine = ""
        if anyPropertiesRequireAssignmentLogic {
            // Don't insert the temporary value variable if it will not be used.
            // Currently it is only used for URLs, Typed Collections and Other model classes.
            tmpVariableLine = indentation + "id value = nil;\n"
        }


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
            tmpVariableLine,
            propertyLines.joinWithSeparator("\n\n"),
            "",
            "    return self;",
            "}"
        ]
        if self.isBaseClass() == false {
            lines.insert(indentation + "[self \(self.parentClassName())DidInitializeWithDictionary:modelDictionary];\n", atIndex: lines.count - 2)
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

        var lines = [
            "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder",
            "{",
            "    NSParameterAssert(builder);",
            superInitCall,
            propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
            "    return self;",
            "}"
        ]
        if self.isBaseClass() == false {
            lines.insert(indentation + "[self \(self.parentClassName())DidInitialize];", atIndex: lines.count - 2)
        }
        return lines.joinWithSeparator("\n")
    }

    func renderBuilderInitWithModelObject() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            return "_\(formattedPropName) = modelObject.\(formattedPropName);"
        }
        let indentation = "    "
        var superInitCall = indentation + "if (!(self = [super initWithModel:modelObject])) { return self; }"
        if self.isBaseClass() {
            superInitCall = indentation + "if (!(self = [super init])) { return self; }"
        }
        let lines = [
            "- (instancetype)initWithModel:(\(self.className) *)modelObject",
            "{",
            "    NSParameterAssert(modelObject);",
            superInitCall,
            propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
            "    return self;",
            "}"
        ]
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
            let decodeStmt = ObjectiveCProperty(descriptor: property).renderDecodeWithCoderStatement()
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
        if self.isBaseClass() == false {
            lines.insert(indentation + "[self \(self.parentClassName())DidInitialize];\n", atIndex: lines.count - 2)
        }
        return lines.joinWithSeparator("\n")
    }

    func renderEncodeWithCoder() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderEncodeWithCoderStatement() + ";"
        }
        let indentation = "    "
        if self.isBaseClass() {
            return [
                "- (void)encodeWithCoder:(NSCoder *)aCoder",
                "{",
                propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
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


    func renderMergeWithDictionary() -> String {
        let indentation = "    "

        func renderMergeForProperty(propertyDescriptor: ObjectSchemaProperty) -> String {
            var lines: [String] = []
            let property = ObjectiveCProperty(descriptor: propertyDescriptor, className: self.className)
            let formattedPropName = propertyDescriptor.name.snakeCaseToPropertyName()

            if property.propertyRequiresAssignmentLogic() {
                let propFromDictionary = "valueOrNil(modelDictionary, @\"\(propertyDescriptor.name)\")"
                let propertyLines = property.propertyMergeStatementFromDictionary("builder", className: self.className).map({ indentation + $0 })
                lines = ["value = \(propFromDictionary);",
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

        let anyPropertiesRequireAssignmentLogic = self.objectDescriptor.properties.map({
            ObjectiveCProperty(descriptor: $0, className: self.className).propertyRequiresAssignmentLogic()}).reduce(false) {
            (sum, nextVal) in
            return sum || nextVal
        }


        var tmpVariableLine = ""
        if anyPropertiesRequireAssignmentLogic {
            // Don't insert the temporary value variable if it will not be used.
            // Currently it is only used for URLs, Typed Collections and Other model classes.
            tmpVariableLine = indentation + indentation + "id value = nil;"
        }
        let lines = [
        "- (instancetype)mergeWithDictionary:(NSDictionary *)modelDictionary",
        "{",
        "   NSParameterAssert(modelDictionary);",
        "   \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWithModel:self];",

        "   [modelDictionary enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {",
        "        if (obj == [NSNull null]) { return; }",
            tmpVariableLine,
            propertyLines.joinWithSeparator("\n\n"),
        "   }];",
        "   return [builder build];",
        "}"
        ]
        return lines.joinWithSeparator("\n")
    }


    func renderStringEnumUtilityMethods() -> String {
        let enumProperties = self.objectDescriptor.properties.filter({ ObjectiveCProperty(descriptor: $0, className: self.className).isEnumPropertyType() && $0.jsonType == JSONType.String })

        let indentation = "    "

        let enumMethods: [String] = enumProperties.map { (prop: ObjectSchemaProperty) -> String in
            assert(prop.defaultValue != nil, "We need a default value for code generation of this string enum.")
            let objcProp = ObjectiveCProperty(descriptor: prop, className: self.className)
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
        let propertyNames = self.classProperties().filter { $0.jsonType == JSONType.Pointer }.map { $0.name }

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
                "    ];"
            ]
        }
        lines.insert("- (NSArray<NSString *> *)modelPropertyNames", atIndex: 0)
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

    func renderBuilderImplementation() -> String {
        let lines = [
            "@implementation \(self.builderClassName)",
            self.renderBuilderInitWithModelObject(),
            self.renderBuildMethod(),
            "@end"
        ]
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
                self.renderMergeWithDictionary(),
                self.renderModelPropertyNames(),
                self.pragmaMark("NSCopying implementation"),
                self.renderCopyWithZone(),
                "@end"
            ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
            return lines.joinWithSeparator("\n\n")

        }

        let lines = [
            "@implementation \(self.className)",
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
            self.renderMergeWithDictionary(),
            self.renderModelPropertyNames(),
            "@end"
        ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
        return lines.joinWithSeparator("\n\n")
    }

    func renderFile() -> String {
        let lines = [
            self.renderCommentHeader(),
            self.renderImports(),
            self.renderUtilityFunctions(),
            self.renderImplementation(),
            self.renderBuilderImplementation()
        ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
        return lines.joinWithSeparator("\n\n")
    }
}
