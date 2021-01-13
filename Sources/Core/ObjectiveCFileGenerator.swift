//
//  objectivec.swift
//  Plank
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

// MARK: File Generation Manager

struct ObjectiveCFileGenerator: FileGeneratorManager {
    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> [FileGenerator] {
        let rootsRenderer = ObjCModelRenderer(rootSchema: descriptor, params: generatorParameters)

        return [
            ObjCHeaderFile(roots: rootsRenderer.renderRoots(), className: rootsRenderer.className),
            ObjCImplementationFile(roots: rootsRenderer.renderRoots(), className: rootsRenderer.className),
        ]
    }

    static func runtimeFiles() -> [FileGenerator] {
        return [ObjCRuntimeHeaderFile(), ObjCRuntimeImplementationFile()]
    }
}

private extension FileGenerator {
    var objcDefaultIndent: Int {
        return 4
    }
}

struct ObjCHeaderFile: FileGenerator {
    let roots: [ObjCIR.Root]
    let className: String

    var fileName: String {
        return "\(className).h"
    }

    var indent: Int {
        return objcDefaultIndent
    }

    func renderFile(_ parameters: GenerationParameters) -> String {
        let output = (
            [self.renderCommentHeader()] +
                roots.compactMap { $0.renderHeader(parameters).joined(separator: "\n") }
        )
        .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
        .filter { $0 != "" }
        .joined(separator: "\n\n")
        return output
    }
}

struct ObjCImplementationFile: FileGenerator {
    let roots: [ObjCIR.Root]
    let className: String

    var fileName: String {
        return "\(className).m"
    }

    var indent: Int {
        return objcDefaultIndent
    }

    func renderFile(_ parameters: GenerationParameters) -> String {
        let output = (
            [self.renderCommentHeader()] +
                roots.map { $0.renderImplementation(parameters).joined(separator: "\n") }
        )
        .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
        .filter { $0 != "" }
        .joined(separator: "\n\n")
        return output
    }
}

struct ObjCRuntimeFile {
    static func renderRoots() -> [ObjCIR.Root] {
        return [
            ObjCIR.Root.macro([
                "#if __has_attribute(noescape)",
                "   #define PLANK_NOESCAPE __attribute__((noescape))",
                "#else",
                "   #define PLANK_NOESCAPE",
                "#endif",
            ].joined(separator: "\n")),

            ObjCIR.Root.optionSetEnum(
                name: "PlankModelInitType",
                values: [
                    EnumValue<Int>(defaultValue: 0, description: "Default"),
                    EnumValue<Int>(defaultValue: 1, description: "FromMerge"),
                    EnumValue<Int>(defaultValue: 2, description: "FromSubmerge"),
                ]
            ),
            // TODO: Add another root for constant variables instead of using Macro
            ObjCIR.Root.macro("NS_ASSUME_NONNULL_BEGIN"),
            ObjCIR.Root.macro("static NSValueTransformerName const kPlankDateValueTransformerKey = @\"kPlankDateValueTransformerKey\";"),
            ObjCIR.Root.macro("static NSNotificationName const kPlankDidInitializeNotification = @\"kPlankDidInitializeNotification\";"),
            ObjCIR.Root.macro("static NSString *const kPlankInitTypeKey = @\"kPlankInitTypeKey\";"),
            ObjCIR.Root.function(
                ObjCIR.method("NSString *debugDescriptionForFields(NSArray *descriptionFields)") { [
                    "NSMutableString *stringBuf = [NSMutableString string];",
                    "NSString *newline = @\"\\n\";",
                    "NSString *format = @\"    %@\";",
                    ObjCIR.forStmt("id obj in descriptionFields") { [
                        ObjCIR.ifElseStmt("[obj isKindOfClass:[NSArray class]]") { [
                            "NSArray<NSString *> *objArray = (NSArray *)obj;",
                            ObjCIR.forStmt("NSString *element in objArray") { [
                                "[stringBuf appendFormat:format, element];",
                                ObjCIR.ifStmt("element != [objArray lastObject]") { [
                                    "[stringBuf appendString:newline];",
                                ] },
                            ] },
                        ] } { [
                            "[stringBuf appendFormat:format, [obj description]];",
                        ] },
                        ObjCIR.ifStmt("obj != [descriptionFields lastObject]") {
                            ["[stringBuf appendString:newline];"]
                        },
                    ] },
                    "return [stringBuf copy];",
                ] }
            ),
            ObjCIR.Root.function(
                ObjCIR.method("NSUInteger PINIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count)") {
                    [
                        "uint64_t result = subhashes[0];",
                        "for (uint64_t ii = 1; ii < count; ++ii) {",
                        "   uint64_t upper = result;",
                        "   uint64_t lower = subhashes[ii];",
                        "   const uint64_t kMul = 0x9ddfea08eb382d69ULL;",
                        "   uint64_t a = (lower ^ upper) * kMul;",
                        "   a ^= (a >> 47);",
                        "   uint64_t b = (upper ^ a) * kMul;",
                        "   b ^= (b >> 47);",
                        "   b *= kMul;",
                        "   result = b;",
                        "}",
                        "return (NSUInteger)result;",
                    ]
                }
            ),
            ObjCIR.Root.function(
                ObjCIR.method("NSError * PlankTypeError(NSString *key, Class expected, Class actual)") {
                    [
                        "NSDictionary *userInfo = nil;",
                        "#if DEBUG",
                        "userInfo = @{ NSDebugDescriptionErrorKey: [NSString stringWithFormat:@\"%@: expected %@ but got %@\", key, expected, actual] };",
                        "#endif",
                        "return [NSError errorWithDomain:NSCocoaErrorDomain code:NSKeyValueValidationError userInfo:userInfo];",
                    ]
                }
            ),
            ObjCIR.Root.macro("NS_ASSUME_NONNULL_END"),
        ]
    }
}

struct ObjCRuntimeHeaderFile: FileGenerator {
    let fileNamePrefix = "PlankModelRuntime"
    let fileNameExtension = "h"
    var fileName: String {
        return "\(fileNamePrefix).\(fileNameExtension)"
    }

    var indent: Int {
        return objcDefaultIndent
    }

    func renderFile(_ parameters: GenerationParameters) -> String {
        let roots: [ObjCIR.Root] = ObjCRuntimeFile.renderRoots()
        let outputs = roots.map { $0.renderHeader(parameters) }.reduce([], +)
        return ([self.renderCommentHeader(), "", "#import <Foundation/Foundation.h>", ""] + outputs)
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .filter { $0 != "" }
            .joined(separator: "\n\n")
    }
}

struct ObjCRuntimeImplementationFile: FileGenerator {
    var fileName: String {
        return "PlankModelRuntime.m"
    }

    var indent: Int {
        return objcDefaultIndent
    }

    func renderFile(_ parameters: GenerationParameters) -> String {
        let roots: [ObjCIR.Root] = ObjCRuntimeFile.renderRoots()
        let outputs = roots.map { $0.renderImplementation(parameters) }.reduce([], +)
        return ([self.renderCommentHeader(), "", "#import <Foundation/Foundation.h>",
                 "",
                 ObjCIR.fileImportStmt(ObjCRuntimeHeaderFile().fileNamePrefix, headerPrefix: parameters[GenerationParameterType.headerPrefix]),
                 outputs.joined(separator: "\n")])
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .filter { $0 != "" }
            .joined(separator: "\n\n")
    }
}
