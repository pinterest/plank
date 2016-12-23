//
//  objectivec.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

// MARK: File Generation Manager

struct ObjectiveCFileGenerator : FileGeneratorManager {
    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> Array<FileGenerator> {

        let rootsRenderer = ObjCRootsRenderer(rootSchema: descriptor, params: generatorParameters)

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
        get {
            return "\(className).h"
        }
    }

    func renderFile() -> String {
        let output = (
            [self.renderCommentHeader()] +
                self.roots.flatMap { $0.renderHeader().joined(separator: "\n") })
            .filter { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != "" }
            .joined(separator: "\n\n")
        return output
    }
}

struct ObjCImplementationFile: FileGenerator {
    let roots: [ObjCIR.Root]
    let className: String

    var fileName: String {
        get {
            return "\(className).m"
        }
    }

    func renderFile() -> String {
        let output = (
            [self.renderCommentHeader()] +
                self.roots.map { $0.renderImplementation().joined(separator: "\n") }).joined(separator: "\n\n")
        return output
    }
}
