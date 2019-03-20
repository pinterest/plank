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
}
