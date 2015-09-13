//
//  ObjCInterfaceFileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation


class ObjectiveCInterfaceFileDescriptor : FileGenerator {
    let objectDescriptor : ObjectSchemaObjectProperty
    let className : String
    let builderClassName : String
    let generationParameters : GenerationParameters
    let parentDescriptor : ObjectSchemaObjectProperty?

    required init(descriptor: ObjectSchemaObjectProperty, generatorParameters : GenerationParameters, parentDescriptor: ObjectSchemaObjectProperty?) {
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
        return "\(self.className).h"
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
        let propertyLines = self.classProperties().map { (property : ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderImplementationDeclaration()
        }

        let parentClassName = NSStringFromClass(NSObject)
        if self.isBaseClass() {
            let lines = [
                "@interface \(self.builderClassName)<ObjectType:\(self.className) *> : \(parentClassName)",
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
        let propertyLines : [String] = self.classProperties().map { (property : ObjectSchemaProperty) -> String in
            return ObjectiveCProperty(descriptor: property).renderInterfaceDeclaration()
        }

        let implementedProtocols = ["NSSecureCoding", "NSCopying"].joinWithSeparator(", ")

        if self.isBaseClass() {
            let lines = [
                "@interface \(self.className)<__covariant BuilderObjectType /* \(self.builderClassName) * */> : NSObject<\(implementedProtocols)>",
                propertyLines.joinWithSeparator("\n"),
                "+ (nullable instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;",
                "- (nullable instancetype)initWithDictionary:(NSDictionary *)modelDictionary NS_DESIGNATED_INITIALIZER;",
                "- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;",
                "- (nullable instancetype)initWithBuilder:(BuilderObjectType)builder NS_DESIGNATED_INITIALIZER;",
                "- (instancetype)copyWithBlock:(void (^)(BuilderObjectType builder))block;",
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
        let referencedForwardDeclarations : [String] = self.objectDescriptor.referencedClasses.flatMap ({ (prop: ObjectSchemaPointerProperty) -> String? in
            if prop.objectiveCStringForJSONType() == self.className {
                return nil
            }
            return "@class \(prop.objectiveCStringForJSONType());"
        })
        var forwardDeclarations = ["@class \(self.builderClassName);"]
        forwardDeclarations.appendContentsOf(referencedForwardDeclarations)
        return forwardDeclarations.sort().joinWithSeparator("\n")
    }

    func renderImports()  -> String {
        if self.isBaseClass() {
            return "#import \"CBLDefines.h\""
        }
        return ["#import \"CBLDefines.h\"", "#import \"\(self.parentClassName()).h\""].joinWithSeparator("\n")
    }

    func renderFile() -> String {
        if self.isBaseClass() {
            let lines = [
                self.renderCommentHeader(),
                "@import Foundation;",
                self.renderImports(),
                self.renderForwardDeclarations(),
                "NS_ASSUME_NONNULL_BEGIN",
                self.renderInterface(),
                self.renderBuilderInterface(),
                "NS_ASSUME_NONNULL_END"
            ]
            return lines.joinWithSeparator("\n\n")
        }
        let lines = [
            self.renderCommentHeader(),
            "@import Foundation;",
            self.renderImports(),
            self.renderForwardDeclarations(),
            self.renderInterface(),
            self.renderBuilderInterface()
        ]
        return lines.joinWithSeparator("\n\n")
    }
}
