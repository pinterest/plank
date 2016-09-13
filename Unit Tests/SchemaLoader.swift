//
//  SchemaLoader.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/17/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation

protocol SchemaLoader {
    func loadSchema(schemaUrl: NSURL) -> ObjectSchemaProperty?
}

class RemoteSchemaLoader: SchemaLoader {
    static let sharedInstance = RemoteSchemaLoader()

    var refs: [NSURL:ObjectSchemaProperty]

    init() {
        self.refs = [NSURL:ObjectSchemaProperty]()
    }

    func loadSchema(schemaUrl: NSURL) -> ObjectSchemaProperty? {
        if let cachedValue = refs[schemaUrl] as ObjectSchemaProperty? {
            return cachedValue
        }

        // Checks for prefix of http to satisfy both http and https urls
        if schemaUrl.scheme!.hasPrefix("http") {
            do {
                // Builds a URL with the access-token necessary to access the schema by appending a query parameter.
                let schemaUrlWithToken = NSURL(string: "\(schemaUrl.absoluteURL!.absoluteString)")!
                if let data = NSURLSession.sharedSession().synchronousDataTaskWithUrl(schemaUrlWithToken) {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! JSONObject

                    if jsonResult["data"] !== NSNull() {
                        refs[schemaUrl] = ObjectSchemaProperty.propertyForJSONObject(jsonResult["data"] as! JSONObject, scopeUrl: schemaUrl)
                    }
                    // TODO (rmalik): Figure out if we should handle NSNull values differently for schemas.
                    // https://phabricator.pinadmin.com/T47
                    return refs[schemaUrl]
                }
            } catch {
                // TODO: Better failure handling and reporting
                // https://phabricator.pinadmin.com/T49
                assert(false)
            }
        } else {
            // Load from local file
            do {
                if let data = NSData(contentsOfFile: schemaUrl.path!) {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! JSONObject

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
