//
//  ObjcEqualityTests.swift
//  CoreTests
//
//  Created by Greg Bolsinga on 6/10/19.
//

import XCTest

@testable import Objective_C

class ObjcEqualityTests: XCTestCase {
//    func testEquality_arrayProp ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.arrayProp = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.arrayProp, t)
//        XCTAssertEqual(e2.arrayProp, t)
//        XCTAssertEqual(e1, e2)
//        XCTAssertEqual(e1.hash,e2.hash)
//    }

    func testEquality_booleanProp() {
        let t = true
        let builder = EverythingBuilder()
        builder.booleanProp = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.booleanProp, t)
        XCTAssertEqual(e2.booleanProp, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_charEnum() {
        let t = EverythingCharEnum.charCase1
        let builder = EverythingBuilder()
        builder.charEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.charEnum, t)
        XCTAssertEqual(e2.charEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_dateProp() {
        let t = NSDate.distantFuture
        let builder = EverythingBuilder()
        builder.dateProp = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.dateProp, t)
        XCTAssertEqual(e2.dateProp, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_intEnum() {
        let t = EverythingIntEnum.intCase1
        let builder = EverythingBuilder()
        builder.intEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.intEnum, t)
        XCTAssertEqual(e2.intEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_intProp() {
        let t = 23
        let builder = EverythingBuilder()
        builder.intProp = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.intProp, t)
        XCTAssertEqual(e2.intProp, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

//    func testEquality_listPolymorphicValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.listPolymorphicValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.listPolymorphicValues, t)
//        XCTAssertEqual(e2.listPolymorphicValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_listWithListAndOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.listWithListAndOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.listWithListAndOtherModelValues, t)
//        XCTAssertEqual(e2.listWithListAndOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_listWithMapAndOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.listWithMapAndOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.listWithMapAndOtherModelValues, t)
//        XCTAssertEqual(e2.listWithMapAndOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_listWithObjectValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.listWithObjectValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.listWithObjectValues, t)
//        XCTAssertEqual(e2.listWithObjectValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_listWithOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.listWithOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.listWithOtherModelValues, t)
//        XCTAssertEqual(e2.listWithOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_listWithPrimitiveValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.listWithPrimitiveValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.listWithPrimitiveValues, t)
//        XCTAssertEqual(e2.listWithPrimitiveValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapPolymorphicValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapPolymorphicValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapPolymorphicValues, t)
//        XCTAssertEqual(e2.mapPolymorphicValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapProp ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapProp = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapProp, t)
//        XCTAssertEqual(e2.mapProp, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapWithListAndOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapWithListAndOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapWithListAndOtherModelValues, t)
//        XCTAssertEqual(e2.mapWithListAndOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapWithMapAndOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapWithMapAndOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapWithMapAndOtherModelValues, t)
//        XCTAssertEqual(e2.mapWithMapAndOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapWithObjectValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapWithObjectValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapWithObjectValues, t)
//        XCTAssertEqual(e2.mapWithObjectValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapWithOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapWithOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapWithOtherModelValues, t)
//        XCTAssertEqual(e2.mapWithOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_mapWithPrimitiveValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.mapWithPrimitiveValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.mapWithPrimitiveValues, t)
//        XCTAssertEqual(e2.mapWithPrimitiveValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }

    func testEquality_nsintegerEnum() {
        let t = EverythingNsintegerEnum.nsintegerCase1
        let builder = EverythingBuilder()
        builder.nsintegerEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.nsintegerEnum, t)
        XCTAssertEqual(e2.nsintegerEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_nsuintegerEnum() {
        let t = EverythingNsuintegerEnum.nsuintegerCase2
        let builder = EverythingBuilder()
        builder.nsuintegerEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.nsuintegerEnum, t)
        XCTAssertEqual(e2.nsuintegerEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_numberProp() {
        let t = 2.3
        let builder = EverythingBuilder()
        builder.numberProp = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.numberProp, t)
        XCTAssertEqual(e2.numberProp, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

//    func testEquality_otherModelProp ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.otherModelProp = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.otherModelProp, t)
//        XCTAssertEqual(e2.otherModelProp, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_polymorphicProp ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.polymorphicProp = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.polymorphicProp, t)
//        XCTAssertEqual(e2.polymorphicProp, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_setProp ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.setProp = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.setProp, t)
//        XCTAssertEqual(e2.setProp, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_setPropWithOtherModelValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.setPropWithOtherModelValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.setPropWithOtherModelValues, t)
//        XCTAssertEqual(e2.setPropWithOtherModelValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_setPropWithPrimitiveValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.setPropWithPrimitiveValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.setPropWithPrimitiveValues, t)
//        XCTAssertEqual(e2.setPropWithPrimitiveValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }
//
//    func testEquality_setPropWithValues ()
//    {
//        let t = 0
//        let builder = EverythingBuilder()
//        builder.setPropWithValues = t
//        let e1 = builder.build()
//        let e2 = builder.build()
//        XCTAssertEqual(e1.setPropWithValues, t)
//        XCTAssertEqual(e2.setPropWithValues, t)
//        XCTAssertEqual(e1, e2)
    // XCTAssertEqual(e1.hash,e2.hash)
//    }

    func testEquality_shortEnum() {
        let t = EverythingShortEnum.shortCase1
        let builder = EverythingBuilder()
        builder.shortEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.shortEnum, t)
        XCTAssertEqual(e2.shortEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_stringEnum() {
        let t = EverythingStringEnum.case1
        let builder = EverythingBuilder()
        builder.stringEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.stringEnum, t)
        XCTAssertEqual(e2.stringEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_stringProp() {
        let t = "test"
        let builder = EverythingBuilder()
        builder.stringProp = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.stringProp, t)
        XCTAssertEqual(e2.stringProp, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_type() {
        let t = "type"
        let builder = EverythingBuilder()
        builder.type = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.type, t)
        XCTAssertEqual(e2.type, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_unsignedCharEnum() {
        let t = EverythingUnsignedCharEnum.unsignedCharCase2
        let builder = EverythingBuilder()
        builder.unsignedCharEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.unsignedCharEnum, t)
        XCTAssertEqual(e2.unsignedCharEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_unsignedIntEnum() {
        let t = EverythingUnsignedIntEnum.unsignedIntCase2
        let builder = EverythingBuilder()
        builder.unsignedIntEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.unsignedIntEnum, t)
        XCTAssertEqual(e2.unsignedIntEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_unsignedShortEnum() {
        let t = EverythingUnsignedShortEnum.charCase2
        let builder = EverythingBuilder()
        builder.unsignedShortEnum = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.unsignedShortEnum, t)
        XCTAssertEqual(e2.unsignedShortEnum, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }

    func testEquality_uriProp() {
        let t = URL(string: "http://example.com")
        let builder = EverythingBuilder()
        builder.uriProp = t
        let e1 = builder.build()
        let e2 = builder.build()
        XCTAssertEqual(e1.uriProp, t)
        XCTAssertEqual(e2.uriProp, t)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e1.hash, e2.hash)
    }
}
