//
//  main.swift
//  PINModel
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

var manager = Manager()

func generateFilesWithInitialUrl(url: NSURL, outputDirectory : NSURL) {
    if let _ = SchemaLoader.sharedInstance.loadSchema(url) as ObjectSchemaProperty? {

        var processedSchemas = Set<NSURL>([])
        repeat {
            SchemaLoader.sharedInstance.refs.map({ (url : NSURL, schema : ObjectSchemaProperty) -> Void in
                if processedSchemas.contains(url) {
                    return
                }

                processedSchemas.insert(url)

                if schema is ObjectSchemaObjectProperty  {
                    let manager = ObjectiveCFileGeneratorManager(descriptor: schema as! ObjectSchemaObjectProperty,
                                                                 generatorParameters: [GenerationParameterType.ClassPrefix : "PI"])
                    for file in manager.filesToGenerate() {
                        let fileContents : String = file.renderFile()
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

            })
        } while (processedSchemas.count != SchemaLoader.sharedInstance.refs.keys.count)
    }
}

//
//generateFilesWithInitialUrl(NSURL(string:"~/json-schema/pin.json".stringByExpandingTildeInPath)!, outputDirectory: NSURL(string: NSFileManager.defaultManager().currentDirectoryPath)!)

manager.register("generate", "Generate Model Files") { argv in
    if let url = argv.shift() {
        if let baseUrl = NSURL(string:url.stringByExpandingTildeInPath) {
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