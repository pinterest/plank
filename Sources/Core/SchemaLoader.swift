//
//  SchemaLoader.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/17/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation

protocol SchemaLoader {
    func loadSchema(_ schemaUrl: URL) -> Schema?
}

class FileSchemaLoader: SchemaLoader {
    static let sharedInstance = FileSchemaLoader()
    static let sharedPropertyLoader = Schema.propertyFunctionForType(loader: FileSchemaLoader.sharedInstance)
    var refs: [URL:Schema]

    init() {
        self.refs = [URL:Schema]()
    }

    func loadSchema(_ schemaUrl: URL) -> Schema? {
        if let cachedValue = refs[schemaUrl] {
            return cachedValue
        }
        // Load from local file
        if let data = try? Data(contentsOf: URL(fileURLWithPath: schemaUrl.path)) {
            if let jsonResult = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! JSONObject {
                refs[schemaUrl] = FileSchemaLoader.sharedPropertyLoader(jsonResult, schemaUrl)
                return refs[schemaUrl]
            } else {
               fatalError("Invalid JSON. Unable to parse schema at URL: \(schemaUrl)")
            }
        } else {
            fatalError("Error loading or parsing schema at URL: \(schemaUrl)")
        }
        return nil
    }
}
