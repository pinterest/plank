//
//  FileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

typealias GenerationParameters = [GenerationParameterType:String]

let formatter = DateFormatter()
let date = Date()

public enum GenerationParameterType {
    case classPrefix
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
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "MM-dd-yyyy 'at' HH:mm:ss"
        
        let calendar = Calendar.current
        let year: Int = (calendar as NSCalendar).components(NSCalendar.Unit.year, from: date).year!
        
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
        return header.joined(separator: "\n")
    }
    
}

func generateFile(_ schema: ObjectSchemaObjectProperty, outputDirectory: URL, generationParameters: GenerationParameters){
    let manager = ObjectiveCFileGeneratorManager(descriptor: schema,
                                                 generatorParameters: generationParameters,
                                                 schemaLoader: RemoteSchemaLoader.sharedInstance)
    for file in manager.filesToGenerate() {
        let fileContents = file.renderFile() + "\n" // Ensure there is exactly one new line a the end of the file.
        do {
            try fileContents.write(
                to: URL(string: file.fileName(), relativeTo: outputDirectory)!,
                atomically: true,
                encoding: String.Encoding.utf8)
        } catch {
            assert(false)
        }
    }
}

func generateFilesWithInitialUrl(_ url: URL, outputDirectory: URL, generationParameters: GenerationParameters) {
    if let _ = RemoteSchemaLoader.sharedInstance.loadSchema(url) as ObjectSchemaProperty? {
        var processedSchemas = Set<URL>([])
        repeat {
            let _ = RemoteSchemaLoader.sharedInstance.refs.map({ (url: URL, schema: ObjectSchemaProperty) -> Void in
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
