//
//  ObjectiveCPropertyTests.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/12/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest
@testable import pinmodel

class ObjectiveCPropertyTests: PINModelTests {
    var baseProperty: AnyProperty!
    var childProperty: AnyProperty!

    override func setUp() {
        super.setUp()
//        self.baseProperty = PropertyFactory.propertyForDescriptor(self.baseImpl.objectDescriptor, className: "PIModel", schemaLoader: self.schemaLoader)
//        self.childProperty = PropertyFactory.propertyForDescriptor(self.childImpl.objectDescriptor, className: "PINotification", schemaLoader: self.schemaLoader)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testThatItDoesNotIncludeTypeInTheNameOfAnEnumEndingWithType()  {
        let integer = integerProperty(descriptorName: "type", className: "PIModel")
        XCTAssertTrue(integer.enumPropertyTypeName() != "PIModelTypeType")
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelType")
    }

    func testThatItCorrectlyHandlesAEnumNameLessThan4Characters()  {
        let integer = integerProperty(descriptorName: "ty", className: "PIModel")
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelTyType")
    }

    fileprivate func integerProperty(descriptorName name: String, className: String) -> ObjectiveCIntegerProperty {
        let propInfo = [
            "type": "integer",
            "enum": [ [ "default" : 0 , "description" : "SYSTEM_RECOMMENDATION" ] ]
        ] as JSONObject

        let descriptor = ObjectSchemaNumberProperty(name: name, objectType: .Integer, propertyInfo: propInfo, sourceId: URL(fileURLWithPath: ""))
        return ObjectiveCIntegerProperty(descriptor: descriptor, className: className, schemaLoader: self.schemaLoader)
    }
}
