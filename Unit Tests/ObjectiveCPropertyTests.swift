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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.baseProperty = PropertyFactory.propertyForDescriptor(self.baseImpl.objectDescriptor, className: "PIModel", schemaLoader: self.schemaLoader)
        self.childProperty = PropertyFactory.propertyForDescriptor(self.childImpl.objectDescriptor, className: "PINotification", schemaLoader: self.schemaLoader)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDirtyPropertiesIVarNameForBaseClass() {
        let dirtyPropertyIVarName = baseProperty.dirtyPropertiesIVarName()
        let expectedDirtyPropertyIVarName = "baseDirtyProperties"
        
        XCTAssertEqual(dirtyPropertyIVarName, expectedDirtyPropertyIVarName)
    }

    func testDirtyPropertiesIVarNameForChildClass() {
        let dirtyPropertyIVarName = childProperty.dirtyPropertiesIVarName()
        let expectedDirtyPropertyIVarName = "dirtyProperties"
        
        XCTAssertEqual(dirtyPropertyIVarName, expectedDirtyPropertyIVarName)
    }
}
