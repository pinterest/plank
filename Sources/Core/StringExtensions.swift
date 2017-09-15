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
    "id": "identifier",
    "bool": "bool_property",
    "class": "class_property",
    "imp": "imp_property",
    "no": "no_property",
    "null": "null_property",
    "protocol": "protocol_property",
    "sel": "sel_property",
    "yes": "yes_property",
    "_bool": "bool_property",
    "_complex": "complex_property",
    "_imaginery": "imaginery_property",
    "atomic": "atomic_property",
    "auto": "auto_property",
    "break": "break_property",
    "bycopy": "bycopy_property",
    "byref": "byref_property",
    "case": "case_property",
    "char": "char_property",
    "const": "const_property",
    "continue": "continue_property",
    "default": "default_property",
    "do": "do_property",
    "double": "double_property",
    "else": "else_property",
    "enum": "enum_property",
    "extern": "extern_property",
    "float": "float_property",
    "for": "for_property",
    "goto": "goto_property",
    "if": "if_property",
    "in": "in_property",
    "inline": "inline_property",
    "inout": "inout_property",
    "int": "int_property",
    "long": "long_property",
    "nil": "nil_property",
    "nonatomic": "nonatomic_property",
    "oneway": "oneway_property",
    "out": "out_property",
    "register": "register_property",
    "restrict": "restrict_property",
    "retain": "retain_property",
    "return": "return_property",
    "self": "self_property",
    "short": "short_property",
    "signed": "signed_property",
    "sizeof": "sizeof_property",
    "static": "static_property",
    "struct": "struct_property",
    "super": "super_property",
    "switch": "switch_property",
    "typedef": "typedef_property",
    "union": "union_property",
    "unsigned": "unsigned_property",
    "void": "void_property",
    "volatile": "volatile_property",
    "while": "while_property"
]

extension String {
    /// All components separated by _ will be capitalized including the first one
    func snakeCaseToCamelCase() -> String {
        var str: String = self

        if let replacementString = objectiveCReservedWordReplacements[self.lowercased()] as String? {
            str = replacementString
        }

        let components = str.components(separatedBy: "_")
        let name = components.map { return $0.uppercaseFirst }
        return name.joined(separator: "")
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

        return name
    }

    func snakeCaseToCapitalizedPropertyName() -> String {
        let formattedPropName = self.snakeCaseToPropertyName()
        let capitalizedFirstLetter = String(formattedPropName[formattedPropName.startIndex]).uppercased()
        return capitalizedFirstLetter + String(formattedPropName.characters.dropFirst())
    }

    /// Get the last n characters of a string
    func suffixSubstring(_ length: Int) -> String {
        return self.substring(from: self.characters.index(self.endIndex, offsetBy: -length))
    }

    /// Uppercase the first character
    var uppercaseFirst: String {
        return String(characters.prefix(1)).uppercased() + String(characters.dropFirst())
    }

    var lowercaseFirst: String {
        return String(characters.prefix(1)).lowercased() + String(characters.dropFirst())
    }
}
