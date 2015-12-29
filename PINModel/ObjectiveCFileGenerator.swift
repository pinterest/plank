//
//  objectivec.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

// MARK: File Generation Manager

class ObjectiveCFileGeneratorManager: FileGeneratorManager {
    let objectDescriptor: ObjectSchemaObjectProperty
    let generatorParams: [GenerationParameterType:String]
    let parentObjectDescriptor: ObjectSchemaObjectProperty?

    required init(descriptor: ObjectSchemaObjectProperty, generatorParameters: [GenerationParameterType:String]) {
        self.objectDescriptor = descriptor
        self.generatorParams = generatorParameters
        self.parentObjectDescriptor = descriptor === BASE_MODEL_INSTANCE ? nil: BASE_MODEL_INSTANCE
    }

    func filesToGenerate() -> Array<FileGenerator> {
        return [
            ObjectiveCInterfaceFileDescriptor(descriptor: objectDescriptor, generatorParameters: self.generatorParams, parentDescriptor: self.parentObjectDescriptor),
            ObjectiveCImplementationFileDescriptor(descriptor: objectDescriptor, generatorParameters: self.generatorParams, parentDescriptor: self.parentObjectDescriptor)
        ]
    }
}
