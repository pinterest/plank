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

        // Checks for prefix of http to satisfy both http and https urls
        if schemaUrl.scheme!.hasPrefix("http") {
//            do {
//                // Builds a URL with the access-token necessary to access the schema by appending a query parameter.
//                let schemaUrlWithToken = URL(string: "\(schemaUrl.absoluteURL.absoluteString)")!
//                if let data = URLSession.shared.synchronousDataTaskWithUrl(schemaUrlWithToken) {
//                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! JSONObject
//
//                    if jsonResult["data"] !== NSNull() {
//                        refs[schemaUrl] = ObjectSchemaProperty.propertyForJSONObject(jsonResult["data"] as! JSONObject, scopeUrl: schemaUrl)
//                    }
//                    // TODO (rmalik): Figure out if we should handle NSNull values differently for schemas.
//                    // https://phabricator.pinadmin.com/T47
//                    return refs[schemaUrl]
//                }
//            } catch {
//                // TODO: Better failure handling and reporting
//                // https://phabricator.pinadmin.com/T49
//                assert(false)
//            }
        } else {
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
        }
        return nil
    }
}
