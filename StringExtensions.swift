//
//  StringExtensions.swift
//  PINModel
//
//  Created by Rahul Malik on 7/24/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation


let OBJC_RESERVED_WORDS_REPLACEMENTS = [
    "description" : "description_text",
    "id" : "identifier"
]

extension String {
    func snakeCaseToCamelCase() -> String {
        let components = self.componentsSeparatedByString("_")
        let name : [String] = components.map { (component : String) -> String in
            return component.capitalizedString
        }
        return name.joinWithSeparator("")
    }

    func snakeCaseToPropertyName() -> String {
        var str : String = self

        if let replacementString = OBJC_RESERVED_WORDS_REPLACEMENTS[self] as String?  {
            str = replacementString
        }

        let components = str.componentsSeparatedByString("_")

        var name : String = ""
        for (idx, component) in components.enumerate() {
            // Hack: Force URL's to be uppercase
            if idx != 0 && component == "url" {
                name += component.uppercaseString
            } else {
                name += idx != 0 ? component.capitalizedString : component
            }
        }

        return name
    }
}
