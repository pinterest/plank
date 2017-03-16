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
            ObjCImplementationFile(roots: rootsRenderer.renderRoots(), className: rootsRenderer.className)
        ]
    }
}

struct ObjCHeaderFile: FileGenerator {
    let roots: [ObjCIR.Root]
    let className: String

    var fileName: String {
        return "\(className).h"
    }

    func renderFile() -> String {
        let output = (
                [self.renderCommentHeader()] +
                self.roots.flatMap { $0.renderHeader().joined(separator: "\n") }
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

    func renderFile() -> String {
        let output = (
                [self.renderCommentHeader()] +
                self.roots.map { $0.renderImplementation().joined(separator: "\n") }
            )
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .filter { $0 != "" }
            .joined(separator: "\n\n")
        return output
    }
}

struct ObjCRuntimeHeaderFile: FileGenerator {
    var fileName: String {
        return "PlankModelRuntime.h"
    }

    func renderFile() -> String {
        let roots: [ObjCIR.Root] = [
            ObjCIR.Root.Enum(
                name: "PIModelInitType",
                values: EnumType.String([
                    EnumValue<String>(defaultValue: "1 << 0", description: "Default"),
                    EnumValue<String>(defaultValue: "1 << 1", description: "Merge"),
                    EnumValue<String>(defaultValue: "1 << 2", description: "Submerge")
                    ], defaultValue:EnumValue<String>(defaultValue: "1 << 0", description: "Default")
                )
            ),

/*
            static NSString *const kPINModelDateValueTransformerKey = @"kPINModelDateValueTransformerKey";

        static NSString *const kPINModelDidInitializeNotification = @"kPINModelDidInitializeNotification";

        static NSString *const kPINModelInitTypeKey = @"kPINModelInitTypeKey";
 */
            ObjCIR.Root.Macro(
                [
                    "#if __has_attribute(noescape)",
                    "   #define PINMODEL_NOESCAPE __attribute__((noescape))",
                    "#else",
                    "   #define PINMODEL_NOESCAPE",
                    "#endif"
                ].joined(separator: "\n")
            ),
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_BEGIN"),

            ObjCIR.Root.Function(
                ObjCIR.method("__unused static inline id _Nullable valueOrNil(NSDictionary *dict, NSString *key)") {[
                    "id value = dict[key];",
                    ObjCIR.ifStmt("value == nil || value == (id)kCFNull") {
                        ["return nil;"]
                    },
                    "return value;"
                ]}
            ),
            ObjCIR.Root.Function(
                ObjCIR.method("__unused static inline NSString *debugDescriptionForFields(NSArray *descriptionFields)") {[
                    "NSMutableString *stringBuf = [NSMutableString string];",
                    "NSString *newline = @\"\n\";",
                    "NSString *format = @\"    %@\";",
                    ObjCIR.forStmt("id obj in descriptionFields") {[
                        ObjCIR.ifElseStmt("[obj isKindOfClass:[NSArray class]]") {[
                            "NSArray<NSString *> *objArray = (NSArray *)obj;",
                            ObjCIR.forStmt("NSString *element in objArray") {[
                                "[stringBuf appendFormat:format, element];",
                                ObjCIR.ifStmt("element != [objArray lastObject]") {[
                                    "[stringBuf appendString:newline];"
                                ]}
                            ]}
                        ]} {[
                            "[stringBuf appendFormat:format, [obj description]];"
                        ]},
                        ObjCIR.ifStmt("obj != [descriptionFields lastObject]") {
                            ["[stringBuf appendString:newline];"]
                        },
                        "return [stringBuf copy];"
                    ]}
                ]}
            ),
            ObjCIR.Root.Function(
                ObjCIR.method("__unused static inline NSUInteger PINIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count)") {
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
                        "return (NSUInteger)result;"
                    ]
                }
            ),
            ObjCIR.Root.Macro("NS_ASSUME_NONNULL_END")

        ]
        return self.renderCommentHeader() +
                "#import <Foundation/Foundation.h>" +
                roots.map { $0.renderHeader() }.reduce([], +).joined(separator: "\n")
    }
}
