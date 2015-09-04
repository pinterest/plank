//
//  ObjCImplementationFileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

class ObjectiveCImplementationFileDescriptor : FileGenerator {
    let objectDescriptor : ObjectSchemaObjectProperty
    let className : String
    let builderClassName : String
    let generationParameters : GenerationParameters

    required init(descriptor: ObjectSchemaObjectProperty, generatorParameters : GenerationParameters) {
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
    }

    func fileName() -> String {
        return "\(self.className).m"
    }


    func pragmaMark(pragmaName : String) -> String {
        return "#pragma mark - \(pragmaName)"
    }

    func renderUtilityFunctions() -> String {
        return [
            "static inline id valueOrNil(NSDictionary *dict, NSString *key) {",
            "    id value = dict[key];",
            "    if (value == nil || value == [NSNull null]) {",
            "        return nil;",
            "    }",
            "    return value;",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderImports() -> String {
        let referencedImportStatements : [String] = self.objectDescriptor.referencedClasses.flatMap({ (prop: ObjectSchemaPointerProperty) -> String? in
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

    func renderClassExtension() -> String {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderImplementationDeclaration()
        }

        let lines = [
            "@interface \(self.className)()",
            propertyLines.joinWithSeparator("\n"),
            "@end"
        ]
        return lines.joinWithSeparator("\n\n")
    }


    func renderModelObjectWithDictionary() -> String {
        return [
            "+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary",
            "{",
            "    return [[self alloc] initWithDictionary:dictionary];",
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

    func renderInitWithDictionary() -> String {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            let indentation = "    "
            if property.propertyRequiresAssignmentLogic() {
                let propFromDictionary = "valueOrNil(modelDictionary, @\"\(property.name)\")"
                let propertyLines = property.propertyAssignmentStatementFromDictionary().map({ indentation + indentation + $0 }).joinWithSeparator("\n")
                let lines = [
                    indentation + "value = \(propFromDictionary);",
                    indentation + "if (value != nil) {" ,
                    propertyLines,
                    indentation + "}"
                ]
                return lines.joinWithSeparator("\n")
            }
            return property.propertyAssignmentStatementFromDictionary().map({ indentation + $0 }).joinWithSeparator("\n")
        }

        let anyPropertiesRequireAssignmentLogic = self.objectDescriptor.properties.map({$0.propertyRequiresAssignmentLogic()}).reduce(false) {
            (sum, nextVal) in
            return sum || nextVal
        }


        var tmpVariableLine = ""
        if anyPropertiesRequireAssignmentLogic {
            // Don't insert the temporary value variable if it will not be used.
            // Currently it is only used for URLs, Typed Collections and Other model classes.
            tmpVariableLine = "    id value = nil;"
        }


        let lines = [
            "- (instancetype) __attribute__((annotate(\"oclint:suppress[high npath complexity]\")))",
            "    initWithDictionary:(NSDictionary *)modelDictionary",
            "{",
            "    NSParameterAssert(modelDictionary);",
            "    if (!(self = [super init])) { return self; }",
            tmpVariableLine,
            propertyLines.joinWithSeparator("\n\n"),
            "    return self;",
            "}"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderCopyWithBlock() -> String {
        let blockName = "\(self.builderClassName)Block"

        let lines = [
            "- (instancetype)copyWithBlock:(\(blockName))block",
            "{",
            "    NSParameterAssert(block);",
            "    \(self.builderClassName) *builder = [[\(self.builderClassName) alloc] initWith\(self.className):self];",
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
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            return "_\(formattedPropName) = builder.\(formattedPropName);"
        }

        let indentation = "    "

        let lines = [
            "- (instancetype)initWithBuilder:(\(self.builderClassName) *)builder",
            "{",
            "    NSParameterAssert(builder);",
            "    if (!(self = [super init])) { return self; }",
            propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
            "    return self;",
            "}"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderBuilderInitWithModelObject() -> String {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            return "_\(formattedPropName) = modelObject.\(formattedPropName);"
        }
        let indentation = "    "
        let lines = [
            "- (instancetype)initWith\(self.className):(\(self.className) *)modelObject",
            "{",
            "    NSParameterAssert(modelObject);",
            "    if (!(self = [super init])) { return self; }",
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

    func renderInitWithCoder() -> String  {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            let decodeStmt = ObjectiveCProperty(descriptor: property).renderDecodeWithCoderStatement()
            return "_\(formattedPropName) = \(decodeStmt);"
        }
        let indentation = "    "
        return [
            "- (instancetype)initWithCoder:(NSCoder *)aDecoder",
            "{",
            "    if (!(self = [super init])) { return self; }",
            propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
            "    return self;",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderEncodeWithCoder() -> String  {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderEncodeWithCoderStatement() + ";"
        }
        let indentation = "    "
        return [
            "- (void)encodeWithCoder:(NSCoder *)aCoder",
            "{",
            propertyLines.map({ indentation + $0 }).joinWithSeparator("\n"),
            "}"
        ].joinWithSeparator("\n")
    }


    func renderCopyWithZone() -> String  {
        return [
            "- (id)copyWithZone:(NSZone *)zone",
            "{",
            "    return self;",
            "}"
        ].joinWithSeparator("\n")
    }

    func renderBuildMethod() -> String  {
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
        let lines = [
            "@implementation \(self.className)",
            self.renderModelObjectWithDictionary(),
            self.renderPolymorphicTypeIdentifier(),
            self.renderDesignatedInit(),
            self.renderInitWithDictionary(),
            self.renderInitWithBuilder(),
            self.pragmaMark("NSSecureCoding implementation"),
            self.renderSupportsSecureCoding(),
            self.renderInitWithCoder(),
            self.renderEncodeWithCoder(),
            self.pragmaMark("Mutation helper methods"),
            self.renderCopyWithBlock(),
            self.pragmaMark("NSCopying implementation"),
            self.renderCopyWithZone(),
            "@end"
        ]
        return lines.joinWithSeparator("\n\n")
    }

    func renderFile() -> String {
        let lines = [
            self.renderCommentHeader(),
            self.renderImports(),
            self.renderClassExtension(),
            self.renderUtilityFunctions(),
            self.renderImplementation(),
            self.renderBuilderImplementation(),
            "" // Newline at the end of file.
        ]
        return lines.joinWithSeparator("\n\n")
    }
}
