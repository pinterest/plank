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
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
//        self.baseProperty = PropertyFactory.propertyForDescriptor(self.baseImpl.objectDescriptor, className: "PIModel", schemaLoader: self.schemaLoader)
//        self.childProperty = PropertyFactory.propertyForDescriptor(self.childImpl.objectDescriptor, className: "PINotification", schemaLoader: self.schemaLoader)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    let enumIntegerPropertyInfo = [
        "type": "integer",
        "enum": [
            [ "default" : 0, "description" : "SYSTEM_RECOMMENDATION" ],
            ] as [[String: AnyObject]]
        ] as JSONObject
    
    func testThatItDoesNotIncludeTypeInTheNameOfAnEnumEndingWithType()  {
        let descriptor = ObjectSchemaNumberProperty(name: "type", objectType: .Integer, propertyInfo: enumIntegerPropertyInfo, sourceId: NSURL())
        let integer = ObjectiveCIntegerProperty(descriptor: descriptor, className: "PIModel", schemaLoader: self.schemaLoader)
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelType")
    }
    
    func testThatItCorrectlyHandlesAEnumNameLessThan4Characters()  {
        let descriptor = ObjectSchemaNumberProperty(name: "ty", objectType: .Integer, propertyInfo: enumIntegerPropertyInfo, sourceId: NSURL())
        let integer = ObjectiveCIntegerProperty(descriptor: descriptor, className: "PIModel", schemaLoader: self.schemaLoader)
        XCTAssertTrue(integer.enumPropertyTypeName() == "PIModelTyType")
    }
    
}
