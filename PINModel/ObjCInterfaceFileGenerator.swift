//
//  ObjCInterfaceFileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation


class ObjectiveCInterfaceFileDescriptor: FileGenerator {
    let objectDescriptor: ObjectSchemaObjectProperty
    let className: String
    let builderClassName: String
    let dirtyPropertyOptionName: String
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
        return "\(self.className).h"
    }

    func protocolName() -> String {
        return "\(self.className)Protocol"
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

    func parentClassName() -> String {
        if let parentSchema = self.parentDescriptor as ObjectSchemaObjectProperty? {
            return ObjectiveCInterfaceFileDescriptor(
                    descriptor: parentSchema,
                    generatorParameters: self.generationParameters,
                    parentDescriptor: nil).className
        }
        return NSStringFromClass(NSObject)
    }

    func parentBuilderClassName() -> String {
        if let parentSchema = self.parentDescriptor as ObjectSchemaObjectProperty? {
            return ObjectiveCInterfaceFileDescriptor(
                descriptor: parentSchema,
                generatorParameters: self.generationParameters,
                parentDescriptor: nil).builderClassName
        }
        return NSStringFromClass(NSObject)
    }

    func renderBuilderInterface() -> String {
        let propertyLines = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            return PropertyFactory.propertyForDescriptor(property, className: self.className).renderImplementationDeclaration()
        }

        let parentClassName = NSStringFromClass(NSObject)
        if self.isBaseClass() {
            let interfaceDeclaration = [
                "@interface \(self.builderClassName)<ObjectType:\(self.className) *> : \(parentClassName)",
                "{",
                "    @protected",
                "    \(self.dirtyPropertyOptionName) _dirtyProperties;",
                "}"
            ]
            let lines = [
                interfaceDeclaration.joinWithSeparator("\n"),
                propertyLines.joinWithSeparator("\n"),
                "- (nullable instancetype)initWithModel:(ObjectType)modelObject;",
                "- (ObjectType)build;",
                "@end"
            ]
            return lines.joinWithSeparator("\n\n")
        } else {
            let lines = [
                "@interface \(self.builderClassName) : \(self.parentBuilderClassName())<\(self.className) *>",
                propertyLines.joinWithSeparator("\n"),
                "@end"
            ]
            return lines.joinWithSeparator("\n\n")
        }
    }

    func renderInterface() -> String {
        let propertyLines: [String] = self.classProperties().map { (property: ObjectSchemaProperty) -> String in
            let prop = PropertyFactory.propertyForDescriptor(property, className: self.className)
            return prop.renderInterfaceDeclaration()
        }

        if self.isBaseClass() {
            let implementedProtocols = ["NSSecureCoding", "NSCopying", self.protocolName()].joinWithSeparator(", ")
            let interfaceDeclaration = [
                "@interface \(self.className)<__covariant BuilderObjectType /* \(self.builderClassName) * */> : NSObject<\(implementedProtocols)>",
                "{",
                "    @protected",
                "    \(self.dirtyPropertyOptionName) _dirtyProperties;",
                "}"
            ]
            let lines = [
                interfaceDeclaration.joinWithSeparator("\n"),
                propertyLines.joinWithSeparator("\n"),
                "+ (NSString *)className;",
                "+ (NSString *)polymorphicTypeIdentifier;",
                "+ (nullable instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;",
                "- (nullable instancetype)initWithDictionary:(NSDictionary *)modelDictionary NS_DESIGNATED_INITIALIZER;",
                "- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;",
                "- (nullable instancetype)initWithBuilder:(BuilderObjectType)builder NS_DESIGNATED_INITIALIZER;",
                "- (instancetype)copyWithBlock:(void (^)(BuilderObjectType builder))block;",
                "- (instancetype)mergeWithDictionary:(NSDictionary *)modelDictionary __attribute__((deprecated));",
                "- (instancetype)mergeWithModel:(PIModel *)modelObject;",
                "// Merges the fields of the receiver with another model. If callDidMerge is NO, this\n" +
                "// method will call the normal post init hook PIModelDidInitialize when merge is complete.\n" +
                "// If callDidInit is YES, this method will call PIModelDidMerge.\n" +
                "- (instancetype)mergeWithModel:(PIModel *)modelObject initType:(PIModelInitType)initType;",
                "- (NSArray<NSString *> *)modelPropertyNames;",
                "- (NSArray<NSString *> *)modelArrayPropertyNames;",
                "- (NSArray<NSString *> *)modelDictionaryPropertyNames;",
                "@end",
            ]
            return lines.joinWithSeparator("\n\n")
        } else {
            let lines = [
                "@interface \(self.className) : \(self.parentClassName())<\(self.builderClassName) *>",
                propertyLines.joinWithSeparator("\n"),
                "@end",
            ]
            return lines.joinWithSeparator("\n\n")

        }
    }

    func renderForwardDeclarations() -> String {
        let referencedForwardDeclarations: [String] = self.objectDescriptor.referencedClasses.flatMap ({ (propDescriptor: ObjectSchemaPointerProperty) -> String? in
            let prop = PropertyFactory.propertyForDescriptor(propDescriptor, className: self.className)
            if prop.objectiveCStringForJSONType() == self.className {
                return nil
            }
            return "@class \(prop.objectiveCStringForJSONType());"
        })
        var forwardDeclarations = ["@class \(self.builderClassName);"]
        if self.isBaseClass() {
            forwardDeclarations.append("@class \(self.className);")
        }
        forwardDeclarations.appendContentsOf(referencedForwardDeclarations)
        return forwardDeclarations.sort().joinWithSeparator("\n")
    }

    func renderDirtyPropertyOptions() -> String {
        let optionsLines: [String] = self.classProperties().enumerate().map { (index, property) in
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

    func renderInitTypeEnum() -> String {
        let lines = [
            "typedef enum {",
            "    PIModelInitTypeDefault = 1 << 0,",
            "    PIModelInitTypeFromMerge = 1 << 1,",
            "    PIModelInitTypeFromSubmerge = 1 << 2",
            "} PIModelInitType;"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderProtocol() -> String {
        let lines = [
            "@protocol \(self.protocolName()) <NSObject>",
            "@optional",
            "- (void)\(self.className)DidInitialize:(PIModelInitType)initType;",
            "- (void)\(self.className)WillDealloc;",
            "@end"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderEnums() -> String {
        let enumProperties = self.objectDescriptor.properties.filter({ PropertyFactory.propertyForDescriptor($0, className: self.className).isEnumPropertyType() })

        let enumDeclarations: [String] = enumProperties.map { (prop: ObjectSchemaProperty) -> String in
            let objcProp = PropertyFactory.propertyForDescriptor(prop, className: self.className)
            return objcProp.renderEnumDeclaration()
        }
        return enumDeclarations.joinWithSeparator("\n\n")
    }

    func renderStringEnumUtilityMethods() -> String {
        let enumProperties = self.objectDescriptor.properties.filter({ PropertyFactory.propertyForDescriptor($0, className: self.className).isEnumPropertyType() && $0.jsonType == JSONType.String })

        let enumDeclarations: [String] = enumProperties.map { (prop: ObjectSchemaProperty) -> String in
            let objcProp = PropertyFactory.propertyForDescriptor(prop, className: self.className)
            return objcProp.renderEnumUtilityMethodsInterface()
        }
        return enumDeclarations.joinWithSeparator("\n\n")
    }

    func renderFrameworkImports() -> String {
        let lines = [
            "#import <Foundation/Foundation.h>"
        ]
        return lines.joinWithSeparator("\n")
    }

    func renderImports() -> String {
        if self.isBaseClass() {
            return ""
        }
        return "#import \"\(self.parentClassName()).h\""
    }

    func renderFile() -> String {
        if self.isBaseClass() {
            let lines = [
                self.renderCommentHeader(),
                self.renderFrameworkImports(),
                self.renderForwardDeclarations(),
                self.renderDirtyPropertyOptions(),
                self.renderInitTypeEnum(),
                "NS_ASSUME_NONNULL_BEGIN",
                self.renderProtocol(),
                self.renderInterface(),
                self.renderBuilderInterface(),
                "NS_ASSUME_NONNULL_END"
            ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
            return lines.joinWithSeparator("\n\n")
        }
        let lines = [
            self.renderCommentHeader(),
            self.renderFrameworkImports(),
            self.renderImports(),
            self.renderEnums(),
            self.renderStringEnumUtilityMethods(),
            self.renderForwardDeclarations(),
            self.renderInterface(),
            self.renderBuilderInterface()
        ].filter { "" != $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
        return lines.joinWithSeparator("\n\n")
    }
}
