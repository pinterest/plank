//
//  ObjectiveCEnumTests.swift
//  CoreTests
//
//  Created by Greg Bolsinga on 5/30/19.
//

import XCTest

@testable import Core

class ObjectiveCEnumTests: XCTestCase {
    func testEnumChar_Negative() {
        let array: [Int] = [-1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.char)
    }

    func testEnumUnsignedChar_UInt8Max_Subtract1() {
        let array = [Int(UInt8.max) - 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedChar)
    }

    func testEnumUnsignedChar_UInt8Max() {
        let array = [Int(UInt8.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedChar)
    }

    func testEnumUnsignedShort_UInt8Max_Add1() {
        let array = [Int(UInt8.max) + 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedShort)
    }

    func testEnumShort_Negative_UInt8Max() {
        let array = [-1, Int(UInt8.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.short)
    }

    func testEnumUnsignedShort_UInt16Max_Subtract1() {
        let array = [Int(UInt16.max) - 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedShort)
    }

    func testEnumUnsignedShort_UInt16Max() {
        let array = [Int(UInt16.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedShort)
    }

    func testEnumUnsignedInt_UInt16Max_Add1() {
        let array = [Int(UInt16.max) + 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedInt)
    }

    func testEnumInt_Negative_UInt16Max() {
        let array = [-1, Int(UInt16.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.int)
    }

    func testEnumUnsignedInt_UInt32Max_Subtract1() {
        let array = [Int(UInt32.max) - 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedInt)
    }

    func testEnumUnsignedInt_UInt32Max() {
        let array = [Int(UInt32.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.unsignedInt)
    }

    func testEnumNSUInteger_UInt16Max_Add1() {
        let array = [Int(UInt32.max) + 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.NSUInteger)
    }

    func testEnumNSInteger_Negative_UInt32Max() {
        let array = [-1, Int(UInt32.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.NSInteger)
    }

    func testEnumNSInteger_Int64Max_Subtract1() {
        let array = [Int(Int64.max) - 1]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.NSUInteger)
    }

    func testEnumNSUInteger_Int64Max() {
        let array = [Int(Int64.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.NSUInteger)
    }

    func testEnumNSInteger_Negative_Int64Max() {
        let array = [-1, Int(Int64.max)]
        let value = EnumType.integer(array.map { EnumValue<Int>(defaultValue: $0, description: "e\($0)") })
        XCTAssertEqual(EnumerationIntegralType.enumerationIntegralTypeFor(value), EnumerationIntegralType.NSInteger)
    }

    // Tests with UInt64 fail to run. plank only has Int internally.
}
