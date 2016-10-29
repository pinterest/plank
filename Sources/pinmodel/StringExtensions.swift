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
        let components = self.components(separatedBy: "_")
        let name: [String] = components.map { (component: String) -> String in
            return component.capitalized
        }
        return name.joined(separator: "")
    }

    func snakeCaseToPropertyName() -> String {
        var str: String = self

        if let replacementString = OBJC_RESERVED_WORDS_REPLACEMENTS[self] as String?  {
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
}
