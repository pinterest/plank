import Foundation
import JavaScriptCore
import XCTest

@testable import Objective_C

class ObjcJavaScriptCoreBridgingTestSuite: XCTestCase {
    static let _context: JSContext = JSContext()!

    override class func setUp() {
        super.setUp()
        injectJSFileIntoContext(fileName: "bundle", context: _context)
    }

    // Inject a js file located in plank/Examples/Shared/
    class func injectJSFileIntoContext(fileName: String, context: JSContext) {
        let jsFileName = "\(fileName).js"
        // The currentDirectoryPath is: plank/Examples/Cocoa/
        let currentPath = FileManager.default.currentDirectoryPath

        let pathURL = URL(fileURLWithPath: currentPath)
        let finalPathURL = pathURL.appendingPathComponent("..")
            .appendingPathComponent("Shared")
            .appendingPathComponent(jsFileName)
        do {
            let bundleContents = try String(contentsOf: finalPathURL, encoding: .utf8)
            context.evaluateScript(bundleContents)
        } catch {
            print("Couldn't inject \(jsFileName) into JSContext")
        }
    }

    var context: JSContext {
        return ObjcJavaScriptCoreBridgingTestSuite._context
    }

    func testImageModelBridgingGetImage() {
        // Expected modelc dictionary
        let imageModelDictionary: JSONDict = [
            "height": 300,
            "width": 200,
            "url": "https://picsum.photos/200/300",
        ]
        let expectedImage = Image(modelDictionary: imageModelDictionary)
        let expectedImageDictionaryRepresentation = expectedImage.dictionaryObjectRepresentation()

        // Get image from js context
        let getTestImageModelJSONFunction = context.objectForKeyedSubscript("getTestImageModelJSON")!
        let jsImageModel = getTestImageModelJSONFunction.call(withArguments: []).toObject() as! JSONDict

        XCTAssert(expectedImage.isEqual(to: Image(modelDictionary: jsImageModel)))
        XCTAssert(jsImageModel == expectedImageDictionaryRepresentation)
    }

    func testImageModelBridgingSendImage() {
        // Expected model dictionary
        let imageModelDictionary: JSONDict = [
            "height": 300,
            "width": 200,
            "url": "https://picsum.photos/200/300",
        ]
        let imageModel = Image(modelDictionary: imageModelDictionary)
        let imageModelDictionaryRepresentation = imageModel.dictionaryObjectRepresentation()

        let testImageModelJSON = context.objectForKeyedSubscript("sendTestImageModelJSON")!
        XCTAssert(testImageModelJSON.call(withArguments: [imageModelDictionaryRepresentation]).toBool())
    }
}
