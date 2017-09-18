//
//  StringExtensions.swift
//  Plank
//
//  Created by Rahul Malik on 7/24/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

#if os(Linux)
    // className is not found in Linux implementation of NSObject https://bugs.swift.org/browse/SR-957
    extension NSString {
        class func className() -> String {
            return "NSString"
        }
    }

    extension NSArray {
        class func className() -> String {
            return "NSArray"
        }
    }

    extension NSURL {
        class func className() -> String {
            return "NSURL"
        }
    }

    extension NSDate {
        class func className() -> String {
            return "NSDate"
        }
    }

    extension NSDictionary {
        class func className() -> String {
            return "NSDictionary"
        }
    }
#endif

prefix operator -->

prefix func --> (strs: [String]) -> String {
    return strs.flatMap { $0.components(separatedBy: "\n").map {$0.indent() } }
        .joined(separator: "\n")
}

prefix func --> (body: () -> [String]) -> String {
    return -->body()
}

// Most of these are derived from https://www.binpress.com/tutorial/objective-c-reserved-keywords/43
// other language conflicts should be ideally added here.
// TODO: Find a way to separate this by language since the reserved keywords will differ.
let objectiveCReservedWordReplacements = [
    "description": "description_text",
    "id": "identifier"
]

let objectiveCReservedWords = Set<String>([
    "@catch()",
    "@class",
    "@dynamic",
    "@end",
    "@finally",
    "@implementation",
    "@interface",
    "@private",
    "@property",
    "@protected",
    "@protocol",
    "@public",
    "@selector",
    "@synthesize",
    "@throw",
    "@try",
    "BOOL",
    "Class",
    "IMP",
    "NO",
    "NULL",
    "Protocol",
    "SEL",
    "YES",
    "_Bool",
    "_Complex",
    "_Imaginery",
    "atomic",
    "auto",
    "break",
    "bycopy",
    "byref",
    "case",
    "char",
    "const",
    "continue",
    "default",
    "do",
    "double",
    "else",
    "enum",
    "extern",
    "float",
    "for",
    "goto",
    "id",
    "if",
    "in",
    "inline",
    "inout",
    "int",
    "long",
    "nil",
    "nonatomic",
    "oneway",
    "out",
    "register",
    "restrict",
    "retain",
    "return",
    "self",
    "short",
    "signed",
    "sizeof",
    "static",
    "struct",
    "super",
    "switch",
    "typedef",
    "union",
    "unsigned",
    "void",
    "volatile",
    "while"
])

extension String {
    /// All components separated by _ will be capitalized including the first one
    func snakeCaseToCamelCase() -> String {
        var str: String = self

        if let replacementString = objectiveCReservedWordReplacements[self.lowercased()] as String? {
            str = replacementString
        }

        let components = str.components(separatedBy: "_")
        let name = components.map { return $0.uppercaseFirst }
        let formattedName = name.joined(separator: "")
        if objectiveCReservedWords.contains(formattedName) {
            return "\(formattedName)Property"
        }
        return formattedName
    }

    /// All components separated by _ will be capitalized execpt the first
    func snakeCaseToPropertyName() -> String {
        var str: String = self

        if let replacementString = objectiveCReservedWordReplacements[self.lowercased()] as String? {
            str = replacementString
        }

        let components = str.components(separatedBy: "_")

        var name: String = ""
        for (idx, component) in components.enumerated() {
            // Hack: Force URL's to be uppercase
            if idx != 0 && component == "url" {
                name += component.uppercased()
                continue
            }

            if idx != 0 {
                name +=	component.uppercaseFirst
            } else {
                name += component.lowercaseFirst
            }
        }

        if objectiveCReservedWords.contains(name) {
            return "\(name)Property"
        }

        return name
    }

    func snakeCaseToCapitalizedPropertyName() -> String {
        let formattedPropName = self.snakeCaseToPropertyName()
        let capitalizedFirstLetter = String(formattedPropName[formattedPropName.startIndex]).uppercased()
        return capitalizedFirstLetter + String(formattedPropName.characters.dropFirst())
    }

    /// Get the last n characters of a string
    func suffixSubstring(_ length: Int) -> String {
        let index = self.characters.index(self.endIndex, offsetBy: -length)
        return String(self[index...])
    }

    /// Uppercase the first character
    var uppercaseFirst: String {
        return String(characters.prefix(1)).uppercased() + String(characters.dropFirst())
    }

    var lowercaseFirst: String {
        return String(characters.prefix(1)).lowercased() + String(characters.dropFirst())
    }
}
