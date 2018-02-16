import Foundation
import XCTest

@testable import Objective_C

// Helper for comparing model dictionaries
public func ==(lhs: [AnyHashable: Any], rhs: [AnyHashable: Any] ) -> Bool {
  return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

class ObjcTestSuite: XCTestCase {

  func testBasicObjectInitialization() {
    let imageModelDictionary: [AnyHashable: Any] = [
      "height": 12,
      "width": 11,
      "url": "http://google.com"
    ]
    let image = Image(modelDictionary: imageModelDictionary)
    XCTAssert(imageModelDictionary["height"] as! Int == image.height, "Image height should be the same")
    XCTAssert(imageModelDictionary["width"] as! Int == image.width, "Image width should be the same")
    XCTAssert(URL(string:imageModelDictionary["url"] as! String)! == image.url!, "URL should be the same")
  }

  func testDictionaryRepresentation() {
    // Test dictionary returned from dictionaryObjectRepresentation is equivalent to the one we used to instnatiate a model object 
    let imageModelDictionary: [AnyHashable: Any] = ["height": (12), "width": (11), "url": "http://google.com"]
      let image = Image(modelDictionary: imageModelDictionary)
      XCTAssert(imageModelDictionary == image.dictionaryObjectRepresentation(), "Image dictionary representation should be the same as the model dictionary.")

      let userModelDictionary: [AnyHashable: Any] = ["id": (123), "first_name": "Michael", "last_name": "Schneider", "image": imageModelDictionary]
      let user = User(modelDictionary: userModelDictionary)

      XCTAssert(userModelDictionary == user.dictionaryObjectRepresentation(), "User dictionary representation should be the same as the model dictionary")
  }
}
