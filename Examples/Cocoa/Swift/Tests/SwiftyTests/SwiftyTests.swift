import Foundation
import XCTest

@testable import Swifty

// Helper for comparing model dictionaries
public func ==(lhs: [AnyHashable: Any], rhs: [AnyHashable: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

class SwiftyTests: XCTestCase {
    func testJSONEncoding() {
        let imageModelDictionary: [AnyHashable: Any] = [
            "height": 12,
            "width": 11,
            "url": "http://google.com"
        ]

        let encoder = JSONEncoder()
        let data = try! encoder.encode(imageModelDictionary)

        let decoder = JSONDecoder()
        let image = try! decoder.decode(Image.self, from: data)
        XCTAssert(imageModelDictionary["height"] as! Int == image.height, "Image height should be the same")
        XCTAssert(imageModelDictionary["width"] as! Int == image.width, "Image width should be the same")
        XCTAssert(URL(string:imageModelDictionary["url"] as! String)! == image.url, "URL should be the same")
    }
}
