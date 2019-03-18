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
    return strs.flatMap { $0.components(separatedBy: "\n").map { $0.isEmpty ? $0 : $0.indent() } }
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
    "id": "identifier",
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
    "while",
])

// TODO: "id" is technically allowed. It's possible not everyone wants this replacement.
let javaReservedWordReplacements = [
    "id": "uid",
]

// https://en.wikipedia.org/wiki/List_of_Java_keywords
let javaReservedWords = Set<String>([
    "abstract",
    "assert",
    "boolean",
    "break",
    "byte",
    "case",
    "catch",
    "char",
    "class",
    "continue",
    "default",
    "do",
    "double",
    "else",
    "enum",
    "exports",
    "extends",
    "final",
    "finally",
    "float",
    "for",
    "if",
    "implements",
    "import",
    "instanceof",
    "int",
    "interface",
    "long",
    "module",
    "native",
    "new",
    "package",
    "private",
    "protected",
    "public",
    "requires",
    "return",
    "short",
    "static",
    "strictfp",
    "super",
    "switch",
    "synchronized",
    "this",
    "throw",
    "throws",
    "transient",
    "try",
    "void",
    "volatile",
    "while",
    "true",
    "null",
    "false",
    "var",
    "const",
    "goto",
])

extension String {
    func indent() -> String {
        // We indent with tabs and in a post process the tabs are changed to a specific number of spaces
        return "\t" + self
    }

    /// All components separated by _ will be capitalized including the first one
    func snakeCaseToCamelCase(_ language: Languages = Languages.objectiveC) -> String {
        var str: String = self

        if language == .objectiveC {
            if let replacementString = objectiveCReservedWordReplacements[self.lowercased()] as String? {
                str = replacementString
            }
        } else if language == .java {
            if let replacementString = javaReservedWordReplacements[self.lowercased()] as String? {
                str = replacementString
            }
        }

        let components = str.components(separatedBy: "_")
        let name = components.map { $0.uppercaseFirst }
        let formattedName = name.joined(separator: "")
        if language == .objectiveC {
            if objectiveCReservedWords.contains(formattedName) {
                return "\(formattedName)Property"
            }
        } else if language == .java {
            if javaReservedWords.contains(formattedName) {
                return "\(formattedName)Property"
            }
        }
        return formattedName
    }

    /// All components separated by _ will be capitalized execpt the first
    func snakeCaseToPropertyName(_ language: Languages = Languages.objectiveC) -> String {
        var str: String = self

        if language == .objectiveC {
            if let replacementString = objectiveCReservedWordReplacements[self.lowercased()] as String? {
                str = replacementString
            }
        } else if language == .java {
            if let replacementString = javaReservedWordReplacements[self.lowercased()] as String? {
                str = replacementString
            }
        }

        let components = str.components(separatedBy: "_")

        var name: String = ""

        for (idx, component) in components.enumerated() {
            // Hack: Force URL's to be uppercase if they appear
            if idx != 0, components.count > 1, component == "url" {
                name += component.uppercased()
                continue
            }

            if idx != 0 {
                name += component.uppercaseFirst
            } else {
                name += component.lowercaseFirst
            }
        }

        if language == .objectiveC {
            if objectiveCReservedWords.contains(name) {
                return "\(name)Property"
            }
        } else if language == .java {
            if javaReservedWords.contains(name) {
                return "\(name)Property"
            }
        }

        return name
    }

    func snakeCaseToCapitalizedPropertyName(_ language: Languages = Languages.objectiveC) -> String {
        let formattedPropName = snakeCaseToPropertyName(language)
        let capitalizedFirstLetter = String(formattedPropName[formattedPropName.startIndex]).uppercased()
        return capitalizedFirstLetter + String(formattedPropName.dropFirst())
    }

    /// Get the last n characters of a string
    func suffixSubstring(_ length: Int) -> String {
        let index = self.index(endIndex, offsetBy: -length)
        return String(self[index...])
    }

    /// Uppercase the first character
    var uppercaseFirst: String {
        return String(prefix(1)).uppercased() + String(dropFirst())
    }

    var lowercaseFirst: String {
        return String(prefix(1)).lowercased() + String(dropFirst())
    }
}
