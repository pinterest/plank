//
//  ObjectiveCInitTests.swift
//  plank
//
//  Created by rmalik on 2/15/17.
//
//

import XCTest

@testable import Core

class ObjectiveCInitTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOneOfInit() {
        let properties = [
            "oneOf": [
                ["type": "object"],
                ["type": "number"]
            ]
        ] as JSONObject

        let schemaLoader = MockSchemaLoader(schema: .oneOf(types: [.map(valueType: nil), .float]), url: URL(string: "http://google.com/")!)
        let propSchemaFn = Schema.propertyFunctionForType(loader: schemaLoader)

        if let prop = propSchemaFn(properties, URL(string: "http://google.com/")!) {
            let schema = SchemaObjectRoot(
                name: "request",
                properties: ["response_data": prop],
                extends: nil,
                algebraicTypeIdentifier: nil
            )

            let renderer = ObjCModelRenderer(rootSchema: schema, params: [:])
            let output = renderer.renderInitWithModelDictionary()
            XCTAssert(output.render().count > 0)
        }
    }
}
