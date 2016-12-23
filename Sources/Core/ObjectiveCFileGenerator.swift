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
        return [
            //ObjectiveCInterfaceFileDescriptor(descriptor: descriptor,
            //                                  generatorParameters: generatorParameters),
            ObjCImplementationFile(rootSchema: descriptor, params: generatorParameters)
        ]
    }
}
