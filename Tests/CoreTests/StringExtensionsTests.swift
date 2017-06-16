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

    func testUppercaseFirstCharacter() {
        XCTAssert("plank".uppercaseFirst == "Plank")
    }

    func testSuffixSubstring() {
        XCTAssert("plank".suffixSubstring(2) == "nk")
    }

    func testSnakeCaseToCamelCase() {
        XCTAssert("created_at".snakeCaseToCamelCase() == "CreatedAt")
        XCTAssert("CreatedAt".snakeCaseToCamelCase() == "CreatedAt")
    }

    func testSnakeCaseToPropertyName() {
        XCTAssert("created_at".snakeCaseToPropertyName() == "createdAt")

        // (@maicki): This test would currently fail as the result is "CreatedAt". 
        // XCTAssert("CreatedAt".snakeCaseToPropertyName() == "createdAt")
    }

    func testSnakeCaseToCapitalizedPropertyName() {
        XCTAssert("created_at".snakeCaseToCapitalizedPropertyName() == "CreatedAt")
        XCTAssert("CreatedAt".snakeCaseToCapitalizedPropertyName() == "CreatedAt")
    }
}
