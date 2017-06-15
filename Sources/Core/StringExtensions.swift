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

extension NSObject {
    // prefix with "pin_" since protocol extensions cannot override parent implementations
    class func pin_className() -> String {
        #if os(Linux)
            return "NSObject"
        #else
            return NSObject.className()
        #endif
    }
}

let objectiveCReservedWordReplacements = [
    "description": "description_text",
    "id": "identifier"
  // TODO: Fill out more objc keywords with replacements.
]

extension String {
    /// All components separated by _ will be capitalized including the first one
    func snakeCaseToCamelCase() -> String {
        var str: String = self

        if let replacementString = objectiveCReservedWordReplacements[self] as String? {
            str = replacementString
        }

        let components = str.components(separatedBy: "_")
        let name = components.map { return $0.uppercaseFirst }
        return name.joined(separator: "")
    }

    /// All components separated by _ will be capitalized execpt the first
    func snakeCaseToPropertyName() -> String {
        var str: String = self

        if let replacementString = objectiveCReservedWordReplacements[self] as String? {
            str = replacementString
        }

        let components = str.components(separatedBy: "_")

        var name: String = ""
        for (idx, component) in components.enumerated() {
            // Hack: Force URL's to be uppercase
            if idx != 0 && component == "url" {
                name += component.uppercased()
            } else {
                name += idx != 0 ? component.capitalized: component
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
}
