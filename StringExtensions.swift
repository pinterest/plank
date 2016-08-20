//
//  StringExtensions.swift
//  PINModel
//
//  Created by Rahul Malik on 7/24/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation


let OBJC_RESERVED_WORDS_REPLACEMENTS = [
    "description": "description_text",
    "id": "identifier"
  // TODO: Fill out more objc keywords with replacements.
]

extension String {
    func snakeCaseToCamelCase() -> String {
        let components = self.componentsSeparatedByString("_")
        let name: [String] = components.map { (component: String) -> String in
            return component.capitalizedString
        }
        return name.joinWithSeparator("")
    }

    func snakeCaseToPropertyName() -> String {
        var str: String = self

        if let replacementString = OBJC_RESERVED_WORDS_REPLACEMENTS[self] as String?  {
            str = replacementString
        }

        let components = str.componentsSeparatedByString("_")

        var name: String = ""
        for (idx, component) in components.enumerate() {
            // Hack: Force URL's to be uppercase
            if idx != 0 && component == "url" {
                name += component.uppercaseString
            } else {
                name += idx != 0 ? component.capitalizedString: component
            }
        }

        return name
    }

    func snakeCaseToCapitalizedPropertyName() -> String {
        let formattedPropName = self.snakeCaseToPropertyName()
        let capitalizedFirstLetter = String(formattedPropName[formattedPropName.startIndex]).uppercaseString
        return capitalizedFirstLetter + String(formattedPropName.characters.dropFirst())
    }
  
    /// Return a new string with the last n characters removed
    func removeLast(length: Int) -> String {
        return self.substringToIndex(self.endIndex.advancedBy(-length))
    }
    
    /// Get the last n characters of a string
    func suffixSubstring(length: Int) -> String {
        return self.substringFromIndex(self.endIndex.advancedBy(-length))
    }
}
