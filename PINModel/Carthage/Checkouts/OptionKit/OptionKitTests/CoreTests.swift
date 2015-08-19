//
//  OptionKitTests.swift
//  OptionKitTests
//
//  Created by Salazar, Alexandros on 9/24/14.
//  Copyright (c) 2014 nomothetis. All rights reserved.
//

import Cocoa
import XCTest
import OptionKit

class OptionKitTests: XCTestCase {
    
    func testParserWithNoOption() {
        let parser = OptionParser()
        parser.parse(["--hello"]).map {opts in
            XCTFail("Empty parser should process no options other than -h|--help; instead processed: \(opts)")
        }
        
        parser.parse(["-v"]).map {opts in
            XCTFail("Empty parser should process no options other than -h|--help; instead processed: \(opts)")
        }
    }
    
    func testParserWithNoParameterShortOption() {
        let optionDescription = Option(trigger:.Short("h"))
        let parser = OptionParser(definitions:[optionDescription])
        
        var params = ["h"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["h"], "Incorrect non-option parameters")
            XCTAssertEqual(0, options.count, "Nothing should have been parsed.")
        case .Failure(let opts):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(opts)")
        }
        
        params = ["-h"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Incorrect option parsed.")
        case .Failure(let err):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(params)")
        }
        
        params = ["-i"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["-h", "--bad-option"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["-h", "-n"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        // Check that order doesn't matter.
        params = ["-h", "lastIsBest"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["lastIsBest"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should not have failed to parse \(params) with error: \(err)")
        }
        
        params = ["firstRules", "-h"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["firstRules"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["sandwiches", "-h", "rock"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["sandwiches", "rock"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
    }
    
    func testInvalidCallsOfNoParamterShortOption() {
        let optionDescription = Option(trigger:.Short("h"))
        let parser = OptionParser(definitions:[optionDescription])
        
        var params = ["--hello"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options: \(params)")
        case .Failure(let err):
            XCTAssert(true, "WAT?")
        }
    }
    
    
    func testParserWithNoParameterLongOption() {
        let optionDescription = Option(trigger:.Long("hello"))
        let parser = OptionParser(definitions:[optionDescription])
        
        var params = ["hello"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["hello"], "Incorrect non-option parameters")
            XCTAssertEqual(0, options.count, "Nothing should have been parsed.")
        case .Failure(let opts):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(opts)")
        }
        
        params = ["--hello"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(params)")
        }
        
        params = ["-i"]
        switch parser.parse(params) {
        case .Success(let _):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["--hello", "--bad-option"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["--hello", "-n"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        // Check that order doesn't matter.
        params = ["--hello", "lastIsBest"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["lastIsBest"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["firstRules", "--hello"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["firstRules"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["sandwiches", "--hello", "rock"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["sandwiches", "rock"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
    }
    
    func testInvalidCallsOfNoParamterLongOption() {
        let optionDescription = Option(trigger:.Long("vroom"), numberOfParameters:0)
        let parser = OptionParser(definitions:[optionDescription])
        
        var params = ["-v"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options: \(params)")
        case .Failure(let err):
            XCTAssert(true, "WAT?")
        }
    }
    
    func testParserWithNoParameterMixedOption() {
        let optionDescription = Option(trigger:.Mixed("h", "hello"))
        let parser = OptionParser(definitions:[optionDescription])
        
        var params = ["h"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["h"], "Incorrect non-option parameters")
            XCTAssertEqual(0, options.count, "No options should have been parsed.")
        case .Failure(let opts):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(opts)")
        }
        
        params = ["-h"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(params)")
        }
        
        params = ["-i"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["-h", "--bad-option"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["-h", "-n"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        // Check that order doesn't matter.
        params = ["-h", "lastIsBest"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["lastIsBest"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should not have failed to parse \(params) with error: \(err)")
        }
        
        params = ["firstRules", "-h"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["firstRules"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["sandwiches", "-h", "rock"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["sandwiches", "rock"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        // Check that the long option also works.
        
        params = ["--hello"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parsing should have succeeded for parser: \(parser), options: \(params)")
        }
        
        params = ["--hello", "--bad-option"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        params = ["--hello", "-n"]
        switch parser.parse(params) {
        case .Success(_):
            XCTFail("Parsing should not have succeeded for parser: \(parser), options:\(params)")
        case .Failure(let err):
            XCTAssert(true, "Success!")
        }
        
        // Check that order doesn't matter.
        params = ["--hello", "lastIsBest"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["lastIsBest"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["firstRules", "--hello"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["firstRules"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["sandwiches", "--hello", "rock"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["sandwiches", "rock"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
    }
    
    func testOptionWithParameters() {
        // One parameter.
        var optionDescription = Option(trigger:.Mixed("h", "hello"), numberOfParameters:1)
        var parser = OptionParser(definitions:[optionDescription])
        
        var params = ["-h", "world"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params); instead generated \(opts)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        params = ["--hello", "--world"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params); instead generated \(opts)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        params = ["--hello", "-w"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params); instead generated \(opts)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        
        optionDescription = Option(trigger:.Mixed("h", "hello"), numberOfParameters:3)
        parser = OptionParser(definitions:[optionDescription])
        
        params = ["-h", "world", "of", "coke"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world", "of", "coke"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Incorrect number of options parsed.")
            XCTAssertNotNil(options[optionDescription], "Parser \(parser) should have parsed \(params)")
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params); instead generated \(parseDataBox)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        params = ["--hello", "world"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params); instead generated \(parseDataBox)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        params = ["--hello", "world", "of"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params); instead generated \(parseDataBox)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
    }
    
    
    func testMixOfParametersAndNoParameters() {
        var optionDescription = Option(trigger:.Mixed("h", "hello"), numberOfParameters:1)
        var optionDescription2 = Option(trigger:.Mixed("p", "pom"))
        var optionDescription3 = Option(trigger:.Mixed("n", "nom"), numberOfParameters:2)
        var parser = OptionParser(definitions:[optionDescription, optionDescription2, optionDescription3])
        var expectedParameters1 = ["world"]
        var expectedParameters2 = []
        var expectedParameters3 = ["boo", "hoo"]
        
        var params = ["--hello", "world", "of"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["of"], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(1, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world", "-p"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(2, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
            
            if let optParams2 = options[optionDescription2] {
                XCTAssertEqual(optParams2, expectedParameters2, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription2)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world", "-p"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(2, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
            
            if let optParams2 = options[optionDescription2] {
                XCTAssertEqual(optParams2, expectedParameters2, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription2)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world", "-p", "-n", "boo", "hoo"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, [], "Incorrect non-option parameters")
            XCTAssertEqual(3, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
            
            if let optParams2 = options[optionDescription2] {
                XCTAssertEqual(optParams2, expectedParameters2, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription2)")
            }
            
            if let optParams3 = options[optionDescription3] {
                XCTAssertEqual(optParams3, expectedParameters3, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription3)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        params = ["--hello", "world", "-p", "-n", "boo", "hoo", "rest"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["rest"], "Incorrect non-option parameters")
            XCTAssertEqual(3, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
            
            if let optParams2 = options[optionDescription2] {
                XCTAssertEqual(optParams2, expectedParameters2, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription2)")
            }
            
            if let optParams3 = options[optionDescription3] {
                XCTAssertEqual(optParams3, expectedParameters3, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription3)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        // Tests that options can be passed at any time
        params = ["-p", "-n", "boo", "hoo", "rest", "--hello", "world"]
        switch parser.parse(params) {
        case .Success(let parseDataBox):
            let (options, rest) = parseDataBox.unbox
            XCTAssertEqual(rest, ["rest"], "Incorrect non-option parameters")
            XCTAssertEqual(3, options.count, "Parser \(parser) should have parsed \(params)")
            if let optParams = options[optionDescription] {
                XCTAssertEqual(optParams, expectedParameters1, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription)")
            }
            
            if let optParams2 = options[optionDescription2] {
                XCTAssertEqual(optParams2, expectedParameters2, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription2)")
            }
            
            if let optParams3 = options[optionDescription3] {
                XCTAssertEqual(optParams3, expectedParameters3, "Incorrect parameters for \(optionDescription)")
            } else {
                XCTFail("No parameters for option \(optionDescription3)")
            }
        case .Failure(let err):
            XCTFail("Parser \(parser) should have properly parsed \(params)")
        }
        
        
        // Now test the failure states: times when all the parameters aren't passed.
        params = ["-p", "-n", "boo", "--hello", "world"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        params = ["-p", "-n", "boo", "--hello"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
        params = ["-n", "boo", "hoo", "--hello"]
        switch parser.parse(params) {
        case .Success(let opts):
            XCTFail("Parser \(parser) should have generated an error with parameters \(params)")
        case .Failure(let err):
            XCTAssert(true, "WTF?")
        }
        
    }
    
}
