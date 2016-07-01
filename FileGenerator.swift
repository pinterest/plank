//
//  FileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

typealias GenerationParameters = [GenerationParameterType:String]

let formatter = NSDateFormatter()
let date = NSDate()

public enum GenerationParameterType {
    case ClassPrefix
}

protocol FileGeneratorManager {
    init(descriptor: ObjectSchemaObjectProperty, generatorParameters: GenerationParameters, schemaLoader: SchemaLoader)
    func filesToGenerate() -> Array<FileGenerator>
}

protocol FileGenerator {
    init(descriptor: ObjectSchemaObjectProperty,
         generatorParameters: GenerationParameters,
         parentDescriptor: ObjectSchemaObjectProperty?,
         schemaLoader: SchemaLoader)
    func fileName() -> String
    func renderFile() -> String
}


extension FileGenerator {
    
    func renderCommentHeader() -> String {
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = .MediumStyle
        formatter.timeZone = NSTimeZone(name: "UTC")
        formatter.dateFormat = "MM-dd-yyyy 'at' HH:mm:ss"
        
        let calendar = NSCalendar.currentCalendar()
        let year: Int = calendar.components(NSCalendarUnit.Year, fromDate: date).year
        
        let header = [
            "//",
            "//  \(self.fileName())",
            "//  Pinterest",
            "//",
            "//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN",
            "//  Copyright (c) \(year) Pinterest, Inc. All rights reserved.",
            "//  @generated",
            "//"
        ]
        return header.joinWithSeparator("\n")
    }
    
}

func generateFile(schema: ObjectSchemaObjectProperty, outputDirectory: NSURL, generationParameters: GenerationParameters){
    let manager = ObjectiveCFileGeneratorManager(descriptor: schema,
                                                 generatorParameters: generationParameters,
                                                 schemaLoader: RemoteSchemaLoader.sharedInstance)
    for file in manager.filesToGenerate() {
        let fileContents = file.renderFile() + "\n" // Ensure there is exactly one new line a the end of the file.
        do {
            try fileContents.writeToURL(
                NSURL(string: file.fileName(), relativeToURL: outputDirectory)!,
                atomically: true,
                encoding: NSUTF8StringEncoding)
        } catch {
            assert(false)
        }
    }
}

func generateFilesWithInitialUrl(url: NSURL, outputDirectory: NSURL, generationParameters: GenerationParameters) {
    if let _ = RemoteSchemaLoader.sharedInstance.loadSchema(url) as ObjectSchemaProperty? {
        var processedSchemas = Set<NSURL>([])
        repeat {
            let _ = RemoteSchemaLoader.sharedInstance.refs.map({ (url: NSURL, schema: ObjectSchemaProperty) -> Void in
                if processedSchemas.contains(url) {
                    return
                }
                
                processedSchemas.insert(url)
                
                if let objectSchema = schema as? ObjectSchemaObjectProperty {
                    generateFile(objectSchema, outputDirectory: outputDirectory, generationParameters: generationParameters)
                }
            })
        } while (processedSchemas.count != RemoteSchemaLoader.sharedInstance.refs.keys.count)
    }
}
