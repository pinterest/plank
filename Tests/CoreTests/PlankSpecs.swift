import SwiftCheck
import XCTest
@testable import Core

class PlankSpecs: XCTestCase {
  func testSwiftCheckWorks() {
    property("equality is reflexive on ints") <- forAll(Int.arbitrary) { (elem: Int) in elem == elem }
  }
}
