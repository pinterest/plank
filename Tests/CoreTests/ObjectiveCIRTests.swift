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

    func testEnumIntegralTypes() {
        var array: [Int] = [-1]
        var value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.char)

        array = [Int(UInt8.max) - 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedChar)

        array = [Int(UInt8.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedChar)

        array = [Int(UInt8.max) + 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedShort)

        array = [-1, Int(UInt8.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.short)

        array = [Int(UInt16.max) - 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedShort)

        array = [Int(UInt16.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedShort)

        array = [Int(UInt16.max) + 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedInt)

        array = [-1, Int(UInt16.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.int)

        array = [Int(UInt32.max) - 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedInt)

        array = [Int(UInt32.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.unsignedInt)

        array = [Int(UInt32.max) + 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.NSUInteger)

        array = [-1, Int(UInt32.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.NSInteger)

        array = [Int(Int64.max) - 1]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.NSUInteger)

        array = [Int(Int64.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.NSUInteger)

        array = [-1, Int(Int64.max)]
        value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegrateTypeFor(value), EnumerationIntegralType.NSInteger)

        // Tests with UInt64 fail to run. plank only has Int internally.
    }
}
