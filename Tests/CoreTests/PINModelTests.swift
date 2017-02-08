//
//  PlankTests.swift
//  Plank
//
//  Created by Andrew Chun on 6/12/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest

import Foundation

@testable import Core

class PlankTests: XCTestCase {

    // Performs a flexible string assertion by making sure the content of the rendered code strings are equal.
    // Flexible string comparison is done by making sure the number of white space tokens are equal between
    //   the rendered code and expected code but doesn't compare the exact number of spaces for each space token.
    //   After counting the number of white space tokens, the content of the non-whitespace tokens are compared
    //   for equality.
    //    i.e. "      " == "  "
    //    i.e. "    if (YES) { }" == " if (YES) { }  "
    class func tokenizeAndAssertFlexibleEquality(_ renderedCode: String, expectedCode: String) {
        func tokenizeAndAssertWhiteSpaceEquality(_ renderedCode: String, expectedCode: String) {
            let renderedWhiteSpaces = renderedCode.components(separatedBy: " ")
                .map { return $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0 == "" }
            let expectedWhiteSpaces = expectedCode.components(separatedBy: " ")
                .map { return $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0 == ""
            }
            XCTAssertEqual(renderedWhiteSpaces.count, expectedWhiteSpaces.count)
        }

        func tokenizeAndAssertContentEquality(_ renderedCode: String, expectedCode: String) {
            let renderedContent = renderedCode.components(separatedBy: " ")
                .map { return $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0 != "" }
            let expectedContent = expectedCode.components(separatedBy: " ")
                .map { return $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0 != "" }
            XCTAssertEqual(renderedContent.count, expectedContent.count)
            XCTAssertEqual(renderedContent, expectedContent)
        }

        tokenizeAndAssertWhiteSpaceEquality(renderedCode, expectedCode: expectedCode)
        tokenizeAndAssertContentEquality(renderedCode, expectedCode: expectedCode)
    }
}
