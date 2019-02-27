//
//  SchemaLoader.swift
//  Plank
//
//  Created by Andrew Chun on 6/17/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation

protocol SchemaLoader {
    func loadSchema(_ schemaUrl: URL) -> Schema
}

class FileSchemaLoader: SchemaLoader {
    static let sharedInstance = FileSchemaLoader()
    static let sharedPropertyLoader = Schema.propertyFunctionForType(loader: FileSchemaLoader.sharedInstance)
    var refs: [URL: Schema]

    init() {
        refs = [URL: Schema]()
    }

    func loadSchema(_ schemaUrl: URL) -> Schema {
        if let cachedValue = refs[schemaUrl] {
            return cachedValue
        }

        // Load from local file
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: schemaUrl.path)) else {
            fatalError("Error loading or parsing schema at URL: \(schemaUrl)")
        }

        guard let jsonResult = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
            fatalError("Invalid JSON. Unable to parse json at URL: \(schemaUrl)")
        }

        guard let jsonDict = jsonResult as? JSONObject else {
            fatalError("Invalid Schema. Expected dictionary as the root object type for schema at URL: \(schemaUrl)")
        }

        let idVal = jsonDict["id"] as? String ?? ""
        guard idVal.hasSuffix(schemaUrl.lastPathComponent) == true else {
            fatalError("Invalid Schema: The value for the `id` (\(idVal) must end with the filename \(schemaUrl.lastPathComponent).")
        }

        guard let schema = FileSchemaLoader.sharedPropertyLoader(jsonDict, schemaUrl) else {
            fatalError("Invalid Schema. Unable to parse schema at URL: \(schemaUrl)")
        }

        refs[schemaUrl] = schema
        return schema
    }
}
