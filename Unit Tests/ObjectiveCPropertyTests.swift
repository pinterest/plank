//
//  ObjectiveCPropertyTests.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/12/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest
//@testable import pinmodel

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
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelType")
    }
    
    func testThatItCorrectlyHandlesAEnumNameLessThan4Characters()  {
        let integer = integerProperty(descriptorName: "ty", className: "PIModel")
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelTyType")
    }
    
    func testThatItStripsTheClassOutOfAnEnumIfDuplicated()  {
        let integer = integerProperty(descriptorName: "model_type", className: "PIModel")
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelType")
    }
    
    private func integerProperty(descriptorName name: String, className: String) -> ObjectiveCIntegerProperty {
        let propertyInfo = [
            "type": "integer",
            "enum": [ [ "default" : 0, "description" : "SYSTEM_RECOMMENDATION" ] ] as [[String: AnyObject]]
        ] as JSONObject

        let descriptor = ObjectSchemaNumberProperty(name: name, objectType: .Integer, propertyInfo: propertyInfo, sourceId: NSURL())
        return ObjectiveCIntegerProperty(descriptor: descriptor, className: className, schemaLoader: self.schemaLoader)
    }
}
