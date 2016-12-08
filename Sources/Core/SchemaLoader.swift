//
//  SchemaLoader.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/17/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation

protocol SchemaLoader {
    func loadSchema(_ schemaUrl: URL) -> ObjectSchemaProperty?
}

class RemoteSchemaLoader: SchemaLoader {
    static let sharedInstance = RemoteSchemaLoader()

    var refs: [URL:ObjectSchemaProperty]

    init() {
        self.refs = [URL:ObjectSchemaProperty]()
    }

    func loadSchema(_ schemaUrl: URL) -> ObjectSchemaProperty? {
        if let cachedValue = refs[schemaUrl] as ObjectSchemaProperty? {
            return cachedValue
        }

        // Load from local file
        do {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: schemaUrl.path)) {
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! JSONObject

                refs[schemaUrl] = ObjectSchemaProperty.propertyForJSONObject(jsonResult, scopeUrl: schemaUrl)
                return refs[schemaUrl]
            }
        } catch {
            // TODO: Better failure handling and reporting
            // https://phabricator.pinadmin.com/T49
            assert(false)
        }

        return nil
    }
}
