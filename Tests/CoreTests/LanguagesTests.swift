//
//  LanguagesTests.swift
//  CoreTests
//
//  Created by Rico Yao on 3/19/19.
//

import XCTest

@testable import Core

class LanguagesTests: XCTestCase {
    func testSnakeCaseToCamelCase() {
        XCTAssert(Languages.objectiveC.snakeCaseToCamelCase("created_at") == "CreatedAt")
        XCTAssert(Languages.objectiveC.snakeCaseToCamelCase("created_aT") == "CreatedAT")
        XCTAssert(Languages.objectiveC.snakeCaseToCamelCase("Created_At") == "CreatedAt")
    }

    func testSnakeCaseToPropertyName() {
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("created_at") == "createdAt")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("CreatedAt") == "createdAt")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("created_At") == "createdAt")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("CreatedAt") == "createdAt")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("CreaTedAt") == "creaTedAt")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("Created_At") == "createdAt")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("Test_url") == "testURL")
        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("url_test") == "urlTest")
    }

    func testSnakeCaseToCapitalizedPropertyName() {
        XCTAssert(Languages.objectiveC.snakeCaseToCapitalizedPropertyName("created_at") == "CreatedAt")
        XCTAssert(Languages.objectiveC.snakeCaseToCapitalizedPropertyName("CreatedAt") == "CreatedAt")
    }

    func testReservedKeywordSubstitution() {
        XCTAssert(Languages.objectiveC.snakeCaseToCapitalizedPropertyName("nil") == "NilProperty")
        XCTAssert(Languages.java.snakeCaseToCapitalizedPropertyName("nil") == "Nil")

        XCTAssert(Languages.objectiveC.snakeCaseToCapitalizedPropertyName("null") == "Null")
        XCTAssert(Languages.java.snakeCaseToCapitalizedPropertyName("null") == "NullProperty")

        XCTAssert(Languages.objectiveC.snakeCaseToPropertyName("id") == "identifier")
        XCTAssert(Languages.java.snakeCaseToPropertyName("id") == "uid")
    }
}
