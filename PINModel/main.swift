//
//  main.swift
//  PINModel
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

// TODO (rmalik): Reserve an access token for the api and also come up with a strategy for appending query parameters for loading remote schemas.
// https://phabricator.pinadmin.com/T44
// https://phabricator.pinadmin.com/T45
let accessTokenString = "access_token=MTQzMTU5NDoxNTAwMjYzNjg3NDUyMTEzMDk6OTIyMzM3MjAzNjg1NDc3NTgwNzoxfDE0Mzk4NTQ5NTA6MC0tOGQwYzJjMzVlMTMyMDI1YTk2MDcwYzJlYWZiYjk1NTM%3D"


let BASE_MODEL_INSTANCE = ObjectSchemaObjectProperty(name: "model", objectType: JSONType.Object,
                                           propertyInfo: ["properties" : [ "id" : [ "type" : "string"] ,
                                                          "additional_local_non_API_properties" : [ "type" : "object"]]],
                                           sourceId: NSURL())
var manager = Manager()

func generateFile(schema: ObjectSchemaObjectProperty, outputDirectory: NSURL) {
    let manager = ObjectiveCFileGeneratorManager(descriptor: schema,
                                                 generatorParameters: [GenerationParameterType.ClassPrefix : "PI"])
    for file in manager.filesToGenerate() {
        let fileContents = file.renderFile() + "\n" // Ensure there is exactly one new line a the end of the file.
        do {
            try fileContents.writeToFile(
                (outputDirectory.URLByAppendingPathComponent(file.fileName()).absoluteString),
                atomically: true,
                encoding: NSUTF8StringEncoding)
        } catch {
            assert(false)
        }
    }
}



func generateFilesWithInitialUrl(url: NSURL, outputDirectory : NSURL) {

    // Generate Base Model
    generateFile(BASE_MODEL_INSTANCE, outputDirectory: outputDirectory)

    // Generate Subclasses
    if let _ = SchemaLoader.sharedInstance.loadSchema(url) as ObjectSchemaProperty? {
        var processedSchemas = Set<NSURL>([])
        repeat {
            let _ = SchemaLoader.sharedInstance.refs.map({ (url : NSURL, schema : ObjectSchemaProperty) -> Void in
                if processedSchemas.contains(url) {
                    return
                }

                processedSchemas.insert(url)

                if schema is ObjectSchemaObjectProperty  {
                    generateFile(schema as! ObjectSchemaObjectProperty,outputDirectory : outputDirectory)
                }

            })
        } while (processedSchemas.count != SchemaLoader.sharedInstance.refs.keys.count)
    }
}

manager.register("generate", "Generate Model Files") { argv in
    if let url = argv.shift() {
        if let baseUrl = NSURL(string:url)?.URLByStandardizingPath {
            if let outputDirectoryString = argv.option("out") {
                generateFilesWithInitialUrl(baseUrl, outputDirectory: NSURL(string: outputDirectoryString)!)
            } else {
                generateFilesWithInitialUrl(baseUrl, outputDirectory: NSURL(string: NSFileManager.defaultManager().currentDirectoryPath)!)
            }
        } else {
            print("Cannot load schema from this URL")
        }
    } else {
        print("Missing URL to JSON-Schema")
    }
}

manager.run()