//
//  ObjectiveCFileGeneratorTests.swift
//  pinmodel
//
//  Created by rmalik on 6/22/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest

import Foundation

@testable import pinmodel

class ObjectiveCFileGeneratorTests: PINModelTests {

    var baseSchema : ObjectSchemaObjectProperty!
    var childSchema : ObjectSchemaObjectProperty!

    override func setUp() {
        super.setUp()
        self.baseSchema = self.schemaLoader.loadSchema(URL(fileURLWithPath: "model.json")) as! ObjectSchemaObjectProperty
        self.childSchema = self.schemaLoader.loadSchema(URL(fileURLWithPath: "notification.json")) as! ObjectSchemaObjectProperty
    }

    func testNumberOfFilesToGenerate() {
        let fileGenerator = ObjectiveCFileGeneratorManager.init(descriptor: self.baseSchema,
                                                                generatorParameters: [GenerationParameterType.classPrefix: "PI"],
                                                                schemaLoader: self.schemaLoader)
        let files = fileGenerator.filesToGenerate()
        XCTAssertEqual(files.count, 2) // We should have two files to generate. Implementation and Interface.
    }

    func testIsBaseClassWithBaseClass() {
        let fileGenerator = ObjectiveCFileGeneratorManager.init(descriptor: self.baseSchema,
                                                                generatorParameters: [GenerationParameterType.classPrefix: "PI"],
                                                                schemaLoader: self.schemaLoader)
        let files = fileGenerator.filesToGenerate()
        for f in files {
            if let implementationFile = f as? ObjectiveCImplementationFileDescriptor {
                XCTAssertTrue(implementationFile.isBaseClass())
                return
            }
        }
        XCTFail() // Shouldn't reach here.
    }

    func testIsBaseClassWithChildClass() {
        let fileGenerator = ObjectiveCFileGeneratorManager.init(descriptor: self.childSchema,
                                                                generatorParameters: [GenerationParameterType.classPrefix: "PI"],
                                                                schemaLoader: self.schemaLoader)
        let files = fileGenerator.filesToGenerate()
        for f in files {
            if let implementationFile = f as? ObjectiveCImplementationFileDescriptor {
                XCTAssertFalse(implementationFile.isBaseClass())
                return
            }
        }
        XCTFail() // Shouldn't reach here.
    }
}
