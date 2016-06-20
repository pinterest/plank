//
//  PINModelTests.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/12/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest
@testable import pinmodel

class PINModelTests: XCTestCase {
    let schemaLoader = MockSchemaLoader()
    var baseImpl: ObjectiveCImplementationFileDescriptor!
    
    var childImpl: ObjectiveCImplementationFileDescriptor!
    
    override func setUp() {
        super.setUp()
        
        self.baseImpl = ObjectiveCImplementationFileDescriptor(
            descriptor: self.schemaLoader.loadSchema(NSURL(fileURLWithPath: "model.json")) as! ObjectSchemaObjectProperty,
            generatorParameters: [GenerationParameterType.ClassPrefix: "PI"],
            parentDescriptor: nil,
            schemaLoader: self.schemaLoader
        )
        
        self.childImpl = ObjectiveCImplementationFileDescriptor(
            descriptor: self.schemaLoader.loadSchema(NSURL(fileURLWithPath: "notification.json")) as! ObjectSchemaObjectProperty,
            generatorParameters: [GenerationParameterType.ClassPrefix: "PI"],
            parentDescriptor: self.baseImpl.objectDescriptor,
            schemaLoader: self.schemaLoader
        )
    }
    
    // Performs a flexible string assertion by making sure the content of the rendered code strings are equal.
    // Flexible string comparison is done by making sure the number of white space tokens are equal between
    //   the rendered code and expected code but doesn't compare the exact number of spaces for each space token.
    //   After counting the number of white space tokens, the content of the non-whitespace tokens are compared
    //   for equality.
    //    i.e. "      " == "  "
    //    i.e. "    if (YES) { }" == " if (YES) { }  "
    class func tokenizeAndAssertFlexibleEquality(renderedCode: String, expectedCode: String) {
        func tokenizeAndAssertWhiteSpaceEquality(renderedCode: String, expectedCode: String) {
            let renderedWhiteSpaces = renderedCode.componentsSeparatedByString(" ").filter { $0 == "" }
            let expectedWhiteSpaces = expectedCode.componentsSeparatedByString(" ").filter { $0 == "" }
            
            XCTAssertEqual(renderedWhiteSpaces.count, expectedWhiteSpaces.count)
        }
        
        func tokenizeAndAssertContentEquality(renderedCode: String, expectedCode: String) {
            let renderedContent = renderedCode.componentsSeparatedByString(" ").filter { $0 != "" }
            let expectedContent = expectedCode.componentsSeparatedByString(" ").filter { $0 != "" }
            
            XCTAssertEqual(renderedContent.count, expectedContent.count)
            XCTAssertEqual(renderedContent, expectedContent)
        }
        
        tokenizeAndAssertWhiteSpaceEquality(renderedCode, expectedCode: expectedCode)
        tokenizeAndAssertContentEquality(renderedCode, expectedCode: expectedCode)
    }
}
