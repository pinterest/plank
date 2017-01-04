//
//  FileGenerator.swift
//  PINModel
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

public typealias GenerationParameters = [GenerationParameterType:String]

let formatter = DateFormatter()
let date = Date()

public enum GenerationParameterType {
    case classPrefix
}

protocol FileGeneratorManager {
    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> Array<FileGenerator>
}

protocol FileGenerator {
    init(rootSchema: SchemaObjectRoot,
         params: GenerationParameters)
    mutating func renderFile() -> String
    var fileName: String { mutating get }
}

protocol FilePrinter {
    func print(statement: String)
}

extension FileGenerator {

    func renderCommentHeader() -> String {
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "MM-dd-yyyy 'at' HH:mm:ss"

        let year: Int = Calendar.current.component(.year, from: date)

        var copy = self

        let header = [
            "//",
            "//  \(copy.fileName)",
            "//  Pinterest", // TODO (allow other copyrights?)
            "//",
            "//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN",
            "//  Copyright (c) \(year) Pinterest, Inc. All rights reserved.",
            "//  @generated",
            "//"
        ]

        return header.joined(separator: "\n")
    }

}

func generateFile(_ schema: SchemaObjectRoot, outputDirectory: URL, generationParameters: GenerationParameters) {
    for var file in ObjectiveCFileGenerator.filesToGenerate(descriptor: schema, generatorParameters: generationParameters) {
        let fileContents = file.renderFile() + "\n" // Ensure there is exactly one new line a the end of the file. // TODO - Have `FilePrinter` take care of things like this.
        do {
            try fileContents.write(
                to: URL(string: file.fileName, relativeTo: outputDirectory)!,
                atomically: true,
                encoding: String.Encoding.utf8)
        } catch {
            assert(false)
        }
    }
}

public func generateFilesWithInitialUrl(_ url: URL, outputDirectory: URL, generationParameters: GenerationParameters) {
    if let _ = RemoteSchemaLoader.sharedInstance.loadSchema(url) as Schema? {
        var processedSchemas = Set<URL>([])
        repeat {
            let _ = RemoteSchemaLoader.sharedInstance.refs.map({ (url: URL, schema: Schema) -> Void in
                if processedSchemas.contains(url) {
                    return
                }
                processedSchemas.insert(url)
                switch schema {
                case .Object(let rootObject):
                    generateFile(rootObject,
                                 outputDirectory: outputDirectory,
                                 generationParameters: generationParameters)
                default:
                    assert(false, "Incorrect Schema for root") // TODO Better error message.
                }
            })
        } while (processedSchemas.count != RemoteSchemaLoader.sharedInstance.refs.keys.count)
    }
}
