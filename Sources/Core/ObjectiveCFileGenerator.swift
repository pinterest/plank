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
