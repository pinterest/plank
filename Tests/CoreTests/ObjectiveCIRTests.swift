//
//  ObjectiveCIRTests.swift
//  CoreTests
//
//  Created by Rahul Malik on 7/23/17.
//

import XCTest

@testable import Core

class ObjectiveCIRTests: XCTestCase {
    func testDirtyPropertyOption() {
        let optionName = dirtyPropertyOption(propertyName: "prop", className: "class")
        XCTAssertEqual(optionName, "classDirtyPropertyProp")
    }

    func testDirtyPropertyOptionMultiWord() {
        let optionName = dirtyPropertyOption(propertyName: "some_prop", className: "class")
        XCTAssertEqual(optionName, "classDirtyPropertySomeProp")
    }

    func testEnumTypeName() {
        XCTAssertEqual(enumTypeName(propertyName: "some_prop_type", className: "class"), "classSomePropType")
    }

    func testEnumToStringName() {
        XCTAssertEqual(enumToStringMethodName(propertyName: "some_prop_type", className: "class"), "classSomePropTypeToString")
    }

    func testEnumFromStringName() {
        XCTAssertEqual(enumFromStringMethodName(propertyName: "some_prop_type", className: "class"), "classSomePropTypeFromString")
    }

    func testStatementSyntax() {
        XCTAssertEqual(
            ObjCIR.stmt("[hello world]"),
            "[hello world];"
        )
    }

    func testMsgSyntax() {
        let expected = "[someVar parameter:arg parameter2:arg2]"
        let actual = ObjCIR.msg("someVar", ("parameter", "arg"), ("parameter2", "arg2"))
        XCTAssertEqual(expected, actual)
    }

    func testBlockSyntax() {
        let actual = ObjCIR.block(["num1", "num2"]) {
            [
                "return num1 + num2;",
            ]
        }
        let expected = [
            "^(num1, num2){",
            "\treturn num1 + num2;",
            "}",
        ].joined(separator: "\n")
        XCTAssertEqual(expected, actual)
    }

    func testScopeSyntax() {
        let expected = [
            "{",
            "int x = 1;".indent(),
            "x--;".indent(),
            "x++;".indent(),
            "}",
        ].joined(separator: "\n")

        let actual = ObjCIR.scope { [
            "int x = 1;",
            "x--;",
            "x++;",
        ] }
        XCTAssertEqual(expected, actual)
    }

    func testNestedScopeSyntax() {
        let expected = [
            "{",
            "int x = 1;".indent(),
            "{".indent(),
            "x--;".indent().indent(),
            "}".indent(),
            "x++;".indent(),
            "}",
        ].joined(separator: "\n")

        let actual = ObjCIR.scope { [
            "int x = 1;",
            ObjCIR.scope { [
                "x--;",
            ] },
            "x++;",
        ] }

        XCTAssertEqual(expected, actual)
    }

    func testIfStmt() {
        let expected = [
            "if (x > 0) {",
            "return true;".indent(),
            "}",
        ].joined(separator: "\n")

        let actual = ObjCIR.ifStmt("x > 0") { [
            "return true;",
        ] }

        XCTAssertEqual(expected, actual)
    }

    func testElseIfStmt() {
        let expected = [
            " else if (x > 0) {",
            "return true;".indent(),
            "}",
        ].joined(separator: "\n")

        let actual = ObjCIR.elseIfStmt("x > 0") { [
            "return true;",
        ] }

        XCTAssertEqual(expected, actual)
    }

    func testElseStmt() {
        let expected = [
            " else {",
            "return true;".indent(),
            "}",
        ].joined(separator: "\n")

        let actual = ObjCIR.elseStmt { [
            "return true;",
        ] }

        XCTAssertEqual(expected, actual)
    }

    func testIfElseStmt() {
        let expected = [
            "if (x > 0) {",
            "return true;".indent(),
            "} else {",
            "return false;".indent(),
            "}",
        ].joined(separator: "\n")
        let actual = ObjCIR.ifElseStmt("x > 0") { [
            "return true;",
        ] } { [
            "return false;",
        ] }
        XCTAssertEqual(expected, actual)
    }

    private func buildEnumDelcarationTest(count: Int, type: String) -> (String, String) {
        var values: [String] = []
        for i in 0..<count {
            values.append("e\(i)")
        }

        var lines = ["typedef NS_ENUM(\(type), enumeration) {"]
        for (index, value) in values.enumerated() {
            if (index < values.count - 1) {
                lines.append("\(value),".indent())
            } else {
                lines.append("\(value)".indent())
            }
        }
        lines.append("};")
        let expected = lines.joined(separator: "\n")

        let actual = ObjCIR.enumStmt("enumeration") { () -> [String] in
            return values
        }

        return (expected, actual)
    }

    func testEnumDeclaration_defaultValues_2_char() {
        let (expected, actual) = buildEnumDelcarationTest(count: 2, type: "unsigned char")

        XCTAssertEqual(expected, actual)
    }

    func testEnumDeclaration_defaultValues_255_char() {
        let (expected, actual) = buildEnumDelcarationTest(count: 255, type: "unsigned char")

        XCTAssertEqual(expected, actual)
    }

    func testEnumDeclaration_defaultValues_256_short() {
        let (expected, actual) = buildEnumDelcarationTest(count: 256, type: "unsigned short")

        XCTAssertEqual(expected, actual)
    }

    func testEnumDeclaration_defaultValues_65535_short() {
        let (expected, actual) = buildEnumDelcarationTest(count: 65535, type: "unsigned short")

        XCTAssertEqual(expected, actual)
    }

    func testEnumDeclaration_defaultValues_65536_NSInteger() {
        let (expected, actual) = buildEnumDelcarationTest(count: 65536, type: "NSInteger")

        XCTAssertEqual(expected, actual)
    }
}
