//
//  Mock.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/17/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation


let TEST_NOTIFICATION_MODEL_INSTANCE = ObjectSchemaObjectProperty(
    name: "notification",
    objectType: JSONType.Object,
    propertyInfo: [
        "title" : "notification",
        "$schema" : "http://json-schema.org/schema#",
        "extends" : ["$ref" : "model.json"],
        "required" : ["id"],
        "description" : "Schema definition of a notification",
        "type" : "object",
        "properties" : [
            "style" : [ "type" : "string" ],
            "sections" : [ "$ref" : "notification_sections.json" ]
        ]
    ], sourceId: NSURL(fileURLWithPath: "notification.json")
)

let TEST_NOTIFICATION_SECTION_MODEL_INSTANCE = ObjectSchemaObjectProperty(
    name: "notification_section",
    objectType: JSONType.Object,
    propertyInfo: [
        "title" : "notification_sections",
        "$schema" : "http://json-schema.org/schema#",
        "extends" : ["$ref" : "model.json"],
        "required" : [],
        "description" : "Schema definition of a notification section",
        "type" : "object",
        "properties" : [
            "data":  [ "type": "object" ],
            "data_type": [ "type": "string" ],
            "string_value": [ "type": "string" ],
            "template": [ "type": "string"],
            "type": [ "type": "string" ]
        ]
    ], sourceId: NSURL(fileURLWithPath: "notification_section_details.json")
)

let TEST_NOTIFICATION_SECTION_DETAILS_MODEL_INSTANCE = ObjectSchemaObjectProperty(
    name: "notification_section_details",
    objectType: JSONType.Object,
    propertyInfo: [
        "title" : "notification_section_details",
        "$schema" : "http://json-schema.org/schema#",
        "extends" : ["$ref" : "model.json"],
        "required" : [],
        "description" : "Schema definition of a notification section details",
        "type" : "object",
        "properties" : [
            "caption": [ "$ref": "notification_section_details.json" ],
            "context_text": [ "$ref": "notification_section_details.json" ],
            "left_object": [ "$ref": "notification_section_details.json" ],
            "message_body": [ "$ref": "notification_section_details.json" ],
            "right_object": [ "$ref": "notification_section_details.json" ]
        ]
    ], sourceId: NSURL(fileURLWithPath: "notification_sections.json")
)

let TEST_BASE_MODEL_INSTANCE = ObjectSchemaObjectProperty(
    name: "model",
    objectType: JSONType.Object,
    propertyInfo: [
        "properties": [
            "id": [ "type": "string"],
            "additional_local_non_API_properties": [ "type": "object"]
        ]
    ],
    sourceId: NSURL()
)

let TEST_ALTERNATE_BASE_MODEL = ObjectSchemaObjectProperty(

    name: "another_model",
    objectType: JSONType.Object,
    propertyInfo: [
        "properties": [
            "id": [ "type": "string"],
            "additional_local_non_API_properties": [ "type": "object"]
        ]
    ],
    sourceId: NSURL()
)

class MockSchemaLoader: SchemaLoader {
    var refs : [String:ObjectSchemaObjectProperty] = [
        NSURL(fileURLWithPath:"notification.json").absoluteString! : TEST_NOTIFICATION_MODEL_INSTANCE,
        NSURL(fileURLWithPath:"notification_sections.json").absoluteString! : TEST_NOTIFICATION_SECTION_MODEL_INSTANCE,
        NSURL(fileURLWithPath:"notification_section_details.json").absoluteString! : TEST_NOTIFICATION_SECTION_DETAILS_MODEL_INSTANCE,
        NSURL(fileURLWithPath:"model.json").absoluteString!: TEST_BASE_MODEL_INSTANCE,
        NSURL(fileURLWithPath:"another_model.json").absoluteString!: TEST_ALTERNATE_BASE_MODEL
    ]

    var loadedSchema = false
    
    func loadSchema(schemaUrl: NSURL) -> ObjectSchemaProperty? {
        loadedSchema = true
        if let objectSchemaProp = refs[schemaUrl.absoluteString!] {
            return objectSchemaProp
        }
        assert(false)
    }
}
