//
//  MockSchemaLoader.swift
//  plank
//
//  Created by rmalik on 2/15/17.
//
//

import Foundation

@testable import Core

struct MockSchemaLoader: SchemaLoader {
    let schema: Schema
    let url: URL
    func loadSchema(_ schemaUrl: URL) -> Schema? {
        if schemaUrl == url {
            return schema
        }
        return nil
    }
}
