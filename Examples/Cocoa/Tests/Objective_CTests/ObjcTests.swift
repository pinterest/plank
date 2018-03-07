import Foundation
import XCTest

@testable import Objective_C

public typealias JSONDict = [AnyHashable: Any]

// Helper for comparing model dictionaries
public func == (lhs: JSONDict, rhs: JSONDict) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

class ObjcTestSuite: XCTestCase {

    func testBasicObjectInitialization() {
        let imageModelDictionary: JSONDict = [
            "height": 12,
            "width": 11,
            "url": "http://google.com"
        ]
        let image = Image(modelDictionary: imageModelDictionary)
        XCTAssert(imageModelDictionary["height"] as! Int == image.height, "Image height should be the same")
        XCTAssert(imageModelDictionary["width"] as! Int == image.width, "Image width should be the same")
        XCTAssert(URL(string: imageModelDictionary["url"] as! String)! == image.url!, "URL should be the same")
    }

    func testDictionaryRepresentation() {
        // Test dictionary returned from dictionaryObjectRepresentation is equivalent to the one we used to instnatiate a model object
        let imageModelDictionary: JSONDict = [
            "height": 12,
            "width": 11,
            "url": "http://google.com"
        ]
        let image = Image(modelDictionary: imageModelDictionary)
        XCTAssert(imageModelDictionary == image.dictionaryObjectRepresentation(), "Image dictionary representation should be the same as the model dictionary.")

        let userModelDictionary: JSONDict = [
            "id": 123,
            "first_name": "Michael",
            "last_name": "Schneider",
            "image": imageModelDictionary,
            "email_frequency": "daily",
            "counts": [
                "foo": 3,
                "bar": 5
            ]
        ]
        let user = User(modelDictionary: userModelDictionary)

        XCTAssert(userModelDictionary == user.dictionaryObjectRepresentation(), "User dictionary representation should be the same as the model dictionary")
    }
}

class ObjcDictionaryRepresentationTestSuite: XCTestCase {

    func assertDictionaryRepresentation(
        _ input: JSONDict,
        cmp: ((JSONDict, JSONDict) -> Bool) = { (dict1: JSONDict, dict2: JSONDict) in dict1 == dict2 }) {
        let everything = Everything(modelDictionary: input)
        let dictRepresentation = everything.dictionaryObjectRepresentation()

        XCTAssert(cmp(input, dictRepresentation), """
                Dictionary representation should be the same as the model dictionary.
                Expected:
                \(input)

                Actual:
                \(dictRepresentation)
            """)
    }

    func testStringProperty() {
        let dict: JSONDict = [
            "string_prop": "some string"
        ]
        assertDictionaryRepresentation(dict)
    }

    func testIntProperty() {
        let dict: JSONDict = [
            "int_prop": 1
        ]
        assertDictionaryRepresentation(dict)
    }

    func testNumberProperty() {
        let dict: JSONDict = [
            "number_prop": 1.2
        ]
        assertDictionaryRepresentation(dict)
    }

    func testBooleanProperty() {
        let dict: JSONDict = [
            "boolean_prop": false
        ]
        assertDictionaryRepresentation(dict)
    }

    func testURIProperty() {
        let dict: JSONDict = [
            "uri_prop": "https://www.pinterest.com"
        ]
        assertDictionaryRepresentation(dict)
    }

    func testMapProperty() {
        let dict: JSONDict = [
            "map_prop": ["foo": "bar"]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testSetProperty() {
        let dict: JSONDict = [
            "set_prop": ["some_set_value", "some_set_value", "some_other_value"] // This could be flaky since we don't enforce ordering when the model is initialized which could break the equality check
        ]
        assertDictionaryRepresentation(dict)
    }

    func testArrayProperty() {
        let dict: JSONDict = [
            "array_prop": ["some_array_value", "another_array_value"]
        ]
        assertDictionaryRepresentation(dict)
    }
    func testModelProperty() {
        let userModelDictionary: JSONDict = [
            "id": 123,
            "email_frequency": "daily"
        ]

        let dict: JSONDict = [
            "other_model_prop": userModelDictionary
        ]

        assertDictionaryRepresentation(dict)
    }

    func testSetWithPrimitiveValuesProperty() {
        // TODO: Determine if set properties should serialize to Array's. This
        // might be necessary if we expect to recreate a model from its dictionary
        // representation
        let dict: JSONDict = [
            "set_prop_with_primitive_values": [1, 2, 3]
        ]

        assertDictionaryRepresentation(dict) { d1, d2 in
            guard let a1 = d1["set_prop_with_primitive_values"] as? [Int], let a2 = d2["set_prop_with_primitive_values"] as? [NSNumber] else {
                print("Unexpected type in dictionary: \(d2)")
                return false
            }
            let s1 = Set(a1)
            let s2 = Set(a2.map { $0.intValue as Int })
            return s1 == s2
        }
    }

    func testSetWithValuesProperty() {
        let dict: JSONDict = [
            "set_prop_with_values": ["foo", "bar"]
        ]

        assertDictionaryRepresentation(dict) { d1, d2 in
            guard let a1 = d1["set_prop_with_values"] as? [String], let a2 = d2["set_prop_with_values"] as? [String] else {
                print("Unexpected type in dictionary: \(d2)")
                return false
            }
            let s1 = Set(a1)
            let s2 = Set(a2)
            return s1 == s2
        }
    }

    func disabled_testSetWithOtherModelsProperty() {
        let userModelDictionary: JSONDict = [
            "id": 123,
            "email_frequency": "daily"
        ]

        let dict: JSONDict = [
            "set_prop_with_other_model_values": [
                userModelDictionary
            ]
        ]

        assertDictionaryRepresentation(dict)
    }

    func testArrayWithPrimitiveValuesProperty() {
        let dict: JSONDict = [
            "list_with_primitive_values": [1, 2, 3]
        ]

        assertDictionaryRepresentation(dict)
    }

    func testArrayWithObjectValuesProperty() {
        let dict: JSONDict = [
            "list_with_object_values": ["foo", "bar"]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testArrayWithOtherModelsProperty() {
        let userModelDictionary: JSONDict = [
            "id": 123,
            "email_frequency": "daily"
        ]
        let dict: JSONDict = [
            "list_with_other_model_values": [userModelDictionary]
        ]

        assertDictionaryRepresentation(dict)
    }

    func testMapWithPrimitiveValuesProperty() {
        let dict: JSONDict = [
            "map_with_primitive_values": [
                "one": 1,
                "two": 2,
                "three": 3
            ]
        ]

        assertDictionaryRepresentation(dict)
    }

    func testMapWithObjectValuesProperty() {
        let dict: JSONDict = [
            "map_with_object_values": [
                "one": "one_val",
                "two": "two_val",
                "three": "three_val"
            ]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testMapWithOtherModelsProperty() {
        let userModelDictionary: JSONDict = [
            "id": 123,
            "email_frequency": "daily"
        ]
        let dict: JSONDict = [
            "map_with_other_model_values": [
                "user": userModelDictionary
            ]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testStringEnum() {
        let dict: JSONDict = [
            "string_enum": "case2"
        ]
        assertDictionaryRepresentation(dict)
    }

    func testIntEnum() {
        let dict: JSONDict = [
            "int_enum": 2
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithModel() {
        let userModelDictionary: JSONDict = [
            "type": "user",
            "id": 123,
            "email_frequency": "daily"
        ]
        let dict: JSONDict = [
            "polymorphic_prop": userModelDictionary
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithSelf() {
        let everythingModelDictionary: JSONDict = [
            // Should we just add type to dictionaries if the property doesn't
            // exist?
            "type": "everything",
            "int_prop": 123
        ]
        let dict: JSONDict = [
            "polymorphic_prop": everythingModelDictionary
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithString() {
        let dict: JSONDict = [
            "polymorphic_prop": "some_value"
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithBool() {
        let dict: JSONDict = [
            "polymorphic_prop": true
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithInt() {
        let dict: JSONDict = [
            "polymorphic_prop": 123
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithNumber() {
        let dict: JSONDict = [
            "polymorphic_prop": 3.14
        ]
        assertDictionaryRepresentation(dict)
    }

    func testPolymorphicPropWithDateTime() {
        // TODO: Implement this
    }

    func testPolymorphicPropWithURI() {
        let dict: JSONDict = [
            "polymorphic_prop": "https://www.pinterest.com"
        ]
        assertDictionaryRepresentation(dict)
    }

    func testListPolymorphicProp() {
        let userModelDictionary: JSONDict = [
            "type": "user",
            "id": 123,
            "email_frequency": "daily"
        ]
        let dict: JSONDict = [
            "list_polymorphic_values": [userModelDictionary]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testMapPolymorphicProp() {
        let userModelDictionary: JSONDict = [
            "type": "user",
            "id": 123,
            "email_frequency": "daily"
        ]
        let dict: JSONDict = [
            "map_polymorphic_values": [
                "user": userModelDictionary
            ]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testNestedListPolymorphicProp() {
        let nestedList = [1, 2, 3]
        let dict: JSONDict = [
            "list_polymorphic_values": [nestedList]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testMapInListPolymorphicProp() {
        let nestedMap = [
            "one": 1,
            "two": 2,
            "three": 3
        ]
        let dict: JSONDict = [
            "list_polymorphic_values": [nestedMap]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testNestedMapPolymorphicProp() {
        let nestedMap = [
            "one": 1,
            "two": 2,
            "three": 3
        ]
        let dict: JSONDict = [
            "map_polymorphic_values": [
                "key": nestedMap
            ]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testNestedListInMapPolymorphicProp() {
        let nestedList = [1, 2, 3]
        let dict: JSONDict = [
            "map_polymorphic_values": [
                "key": nestedList
            ]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testNestedMapWithMapAndModels() {
        let nestedList = [
        "user1": [
            "id": 123,
            "first_name": "Rahul",
            "last_name": "Malik"
        ], 
        "user2": [
            "id": 456,
            "first_name": "Michael",
            "last_name": "Schneider"
        ]]
        let dict: JSONDict = [
            "map_with_map_and_other_model_values": [
                "key": nestedList
            ]
        ]
        assertDictionaryRepresentation(dict)
    }

    func testNestedMapWithListAndModels() {
        let nestedList = [
        [
            "id": 123,
            "first_name": "Rahul",
            "last_name": "Malik"
        ], [
            "id": 456,
            "first_name": "Michael",
            "last_name": "Schneider"
        ]]
        let dict: JSONDict = [
            "map_with_list_and_other_model_values": [
                "key": nestedList
            ]
        ]
        assertDictionaryRepresentation(dict)
    }
    func testNestedListWithMapAndModels() {
        let nestedMap: JSONDict = [
            "user_one": [
                "id": 123,
                "type": "user",
                "first_name": "Rahul",
                "last_name": "Malik"
            ], 
            "user_two": [
                "id": 456,
                "type": "user",
                "first_name": "Michael",
                "last_name": "Schneider"
            ]
        ]
        let list: JSONDict = [
            "list_with_map_and_other_model_values": [nestedMap]
        ]
        assertDictionaryRepresentation(list)
    }

    func testNestedListWithListAndModels() {
        let nestedList = [
            [
                "id": 123,
                "type": "user",
                "first_name": "Rahul",
                "last_name": "Malik"
            ], 
            [
                "id": 456,
                "type": "user",
                "first_name": "Michael",
                "last_name": "Schneider"
            ]
        ]
        let list: JSONDict = [
            "list_with_list_and_other_model_values": [nestedList]
        ]
        assertDictionaryRepresentation(list)
    }
}
