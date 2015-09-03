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
        return "\n".join([
            "static inline id valueOrNil(NSDictionary *dict, NSString *key) {",
            "    id value = dict[key];",
            "    if (value == nil || value == [NSNull null]) {",
            "        return nil;",
            "    }",
            "    return value;",
            "}"
        ])
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
        importStatements.extend(referencedImportStatements)
        return "\n".join(importStatements.sort())
    }

    func renderClassExtension() -> String {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderImplementationDeclaration()
        }

        let lines = [
            "@interface \(self.className)()",
            "\n".join(propertyLines),
            "@end"
        ]
        return "\n\n".join(lines)
    }


    func renderModelObjectWithDictionary() -> String {
        return "\n".join([
            "+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary",
            "{",
            "    return [[self alloc] initWithDictionary:dictionary];",
            "}"
            ])
    }

    func renderPolymorphicTypeIdentifier() -> String {

        return "\n".join([
            "+ (NSString *)polymorphicTypeIdentifier",
            "{",
            "    return @\"\(self.objectDescriptor.name.lowercaseString)\";",
            "}"
        ])
    }

    func renderInitWithDictionary() -> String {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            let indentation = "    "
            if property.propertyRequiresAssignmentLogic() {
                let propFromDictionary = "valueOrNil(modelDictionary, @\"\(property.name)\")"
                return "\n".join([
                    indentation + "value = \(propFromDictionary);",
                    indentation + "if (value != nil) {" ,
                    "\n".join(property.propertyAssignmentStatementFromDictionary().map({ indentation + indentation + $0 })),
                    indentation + "}"
                    ])
            }
            return "\n".join(property.propertyAssignmentStatementFromDictionary().map({ indentation + $0 }))
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
            "\n\n".join(propertyLines),
            "    return self;",
            "}"
        ]
        return "\n".join(lines)
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
        return "\n".join(lines)
    }

    func renderDesignatedInit() -> String {
        let lines = [
            "- (instancetype)init",
            "{",
            "   self = [self initWithDictionary:@{}];",
            "   return self;",
            "}"
        ]
        return "\n".join(lines)
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
            "\n".join(propertyLines.map({ indentation + $0 })),
            "    return self;",
            "}"
        ]
        return "\n".join(lines)
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
            "\n".join(propertyLines.map({ indentation + $0 })),
            "    return self;",
            "}"
        ]
        return "\n".join(lines)
    }

    func renderSupportsSecureCoding() -> String {
        return "\n".join([
            "+ (BOOL)supportsSecureCoding",
            "{",
            "    return YES;",
            "}"
            ])
    }

    func renderInitWithCoder() -> String  {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            let formattedPropName = property.name.snakeCaseToPropertyName()
            let decodeStmt = ObjectiveCProperty(descriptor: property).renderDecodeWithCoderStatement()
            return "_\(formattedPropName) = \(decodeStmt);"
        }
        let indentation = "    "
        return "\n".join([
            "- (instancetype)initWithCoder:(NSCoder *)aDecoder",
            "{",
            "    if (!(self = [super init])) { return self; }",
            "\n".join(propertyLines.map({ indentation + $0 })),
            "    return self;",
            "}"
            ])
    }

    func renderEncodeWithCoder() -> String  {
        let propertyLines : [String] = self.objectDescriptor.properties.map { (property : ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderEncodeWithCoderStatement() + ";"
        }
        let indentation = "    "
        return "\n".join([
            "- (void)encodeWithCoder:(NSCoder *)aCoder",
            "{",
            "\n".join(propertyLines.map({ indentation + $0 })),
            "}"
            ])
    }


    func renderCopyWithZone() -> String  {
        return "\n".join([
            "- (id)copyWithZone:(NSZone *)zone",
            "{",
            "    return self;",
            "}"
        ])
    }

    func renderBuildMethod() -> String  {
        let lines = [
            "- (\(self.className) *)build",
            "{",
            "    return [[\(self.className) alloc] initWithBuilder:self];",
            "}"
        ]
        return "\n".join(lines)
    }

    func renderBuilderImplementation() -> String {
        let lines = [
            "@implementation \(self.builderClassName)",
            self.renderBuilderInitWithModelObject(),
            self.renderBuildMethod(),
            "@end"
        ]
        return "\n\n".join(lines)
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
        return "\n\n".join(lines)
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
        return "\n\n".join(lines)
    }
}
