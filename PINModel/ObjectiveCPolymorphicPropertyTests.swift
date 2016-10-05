//
//  ObjectiveCPolymorphicPropertyTests.swift
//  pinmodel
//
//  Created by Rahul Malik on 1/12/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest

class ObjectiveCPolymorphicPropertyTests: PINModelTests {

    func testObjectiveCTypeWithCommonParents() {
        let schemaProp = ObjectSchemaPolymorphicProperty(name: "test",
                                        objectType: JSONType.Polymorphic,
                                        propertyInfo: ["oneOf" : [
                                            ["$ref": "notification_sections.json"],
                                            ["$ref": "notification_section_details.json"]
                                            ] as AnyObject ],
                                        sourceId: URL(fileURLWithPath: "test.json"))

        let prop = ObjectiveCPolymorphicProperty(descriptor: schemaProp, className: "", schemaLoader: schemaLoader)
        XCTAssertEqual("__kindof PIModel", prop.objectiveCStringForJSONType())
    }

    func testObjectiveCTypeWithParentAndChild() {
        // In the event that we have multiple types where one happens to be a subclass of another
        let schemaProp = ObjectSchemaPolymorphicProperty(name: "test",
                                        objectType: JSONType.Polymorphic,
                                        propertyInfo: ["oneOf" : [
                                            ["$ref": "notification_sections.json"],
                                            ["$ref": "model.json"]
                                            ] as AnyObject ],
                                        sourceId: URL(fileURLWithPath: "test.json"))
        
        let prop = ObjectiveCPolymorphicProperty(descriptor: schemaProp, className: "", schemaLoader: schemaLoader)
        XCTAssertEqual("__kindof PIModel", prop.objectiveCStringForJSONType())
    }

    func testObjectiveCTypeWithNoCommonParent() {
        // In the event that we have multiple types where one happens to be a subclass of another
        let schemaProp = ObjectSchemaPolymorphicProperty(name: "test",
                                        objectType: JSONType.Polymorphic,
                                        propertyInfo: ["oneOf" : [
                                            ["$ref": "notification_sections.json"],
                                            ["$ref": "another_model.json"]
                                            ] as AnyObject ],
                                        sourceId: URL(fileURLWithPath: "test.json"))
        
        let prop = ObjectiveCPolymorphicProperty(descriptor: schemaProp, className: "", schemaLoader: schemaLoader)
        XCTAssertEqual("__kindof NSObject", prop.objectiveCStringForJSONType())
    }
}
