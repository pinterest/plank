//
//  ObjectiveCInterfaceFileDescriptorTests.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/12/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest

import Foundation

@testable import Core

class ObjectiveCInterfaceFileDescriptorTests: PINModelTests {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRenderDirtyPropertyOptions() {
        let dirtyPropertyOptions = baseImpl.renderDirtyPropertyOptions()
        let expectedDirtyPropertyOptions = [
            "struct PIModelDirtyProperties {",
            "    unsigned int PIModelDirtyPropertyAdditionalLocalNonApiProperties:1;",
            "    unsigned int PIModelDirtyPropertyIdentifier:1;",
            "};"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(dirtyPropertyOptions, expectedCode: expectedDirtyPropertyOptions)
    }

    func testDescriptionOnProperty() {
        let interface =  ObjectiveCInterfaceFileDescriptor(
            descriptor: self.schemaLoader.loadSchema(URL(fileURLWithPath: "model.json")) as! ObjectSchemaObjectProperty,
            generatorParameters: [GenerationParameterType.classPrefix: "PI"],
            parentDescriptor: nil,
            schemaLoader: self.schemaLoader
        )

        let propertyDecls = interface.renderPropertyDeclarations()
        XCTAssertTrue(propertyDecls.contains("/* The identifier of the model object */"))
    }
}
