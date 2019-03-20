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

extension String {
    func indent() -> String {
        // We indent with tabs and in a post process the tabs are changed to a specific number of spaces
        return "\t" + self
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

    func replacingNonAlphaNumericsWith(_ replacement: String) -> String {
        let charactersToRemove = NSCharacterSet.alphanumerics.inverted
        return components(separatedBy: charactersToRemove).joined(separator: replacement)
    }
}
