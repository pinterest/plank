//
//  StringExtensionsTests.swift
//  plank
//
//  Created by Michael Schneider on 6/16/17.
//
//

import XCTest

@testable import Core

class StringExtensionsTests: XCTestCase {

    func testUppercaseFirst() {
        XCTAssert("plank".uppercaseFirst == "Plank")
        XCTAssert("Plank".uppercaseFirst == "Plank")
        XCTAssert("plAnK".uppercaseFirst == "PlAnK")
    }

    func testLowercaseFirst() {
        XCTAssert("Plank".lowercaseFirst == "plank")
        XCTAssert("PlAnK".lowercaseFirst == "plAnK")
    }

    func testSuffixSubstring() {
        XCTAssert("plank".suffixSubstring(2) == "nk")
    }

    func testSnakeCaseToCamelCase() {
        XCTAssert("created_at".snakeCaseToCamelCase() == "CreatedAt")
        XCTAssert("created_aT".snakeCaseToCamelCase() == "CreatedAT")
        XCTAssert("CreatedAt".snakeCaseToCamelCase() == "CreatedAt")
    }

    func testSnakeCaseToPropertyName() {
        XCTAssert("created_at".snakeCaseToPropertyName() == "createdAt")
        XCTAssert("CreatedAt".snakeCaseToPropertyName() == "createdAt")
        XCTAssert("created_At".snakeCaseToPropertyName() == "createdAt")
        XCTAssert("CreatedAt".snakeCaseToPropertyName() == "createdAt")
        XCTAssert("CreaTedAt".snakeCaseToPropertyName() == "creaTedAt")
        XCTAssert("Created_At".snakeCaseToPropertyName() == "createdAt")
        XCTAssert("Test_url".snakeCaseToPropertyName() == "testURL")
        XCTAssert("url_test".snakeCaseToPropertyName() == "urlTest")

    }

    func testSnakeCaseToCapitalizedPropertyName() {
        XCTAssert("created_at".snakeCaseToCapitalizedPropertyName() == "CreatedAt")
        XCTAssert("CreatedAt".snakeCaseToCapitalizedPropertyName() == "CreatedAt")
    }

    func testReservedKeywordSubstitution() {
        XCTAssert("nil".snakeCaseToCapitalizedPropertyName() == "NilProperty")
    }
}
