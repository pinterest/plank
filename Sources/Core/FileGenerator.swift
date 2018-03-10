//
//  FileGenerator.swift
//  Plank
//
//  Created by Rahul Malik on 7/23/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

public typealias GenerationParameters = [GenerationParameterType: String]

let formatter = DateFormatter()
let date = Date()

public enum GenerationParameterType {
    case classPrefix
    case recursive
    case includeRuntime
    case indent
    case packageName
}

public enum Languages: String {
    case objectiveC = "objc"
    case flowtype = "flow"
    case java = "java"
}

public protocol FileGeneratorManager {
    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> [FileGenerator]
    static func runtimeFiles() -> [FileGenerator]
}

public protocol FileGenerator {
    func renderFile() -> String
    var fileName: String { mutating get }
    var indent: Int { get }
}

protocol RootRenderer {
    func renderImplementation() -> [String]
}

protocol FileRenderer {
    associatedtype Root: RootRenderer
    var rootSchema: SchemaObjectRoot { get }
    var params: GenerationParameters { get }
    func typeFromSchema(_ param: String, _ schema: SchemaObjectProperty) -> String
    func renderRoots() -> [Root]
}

extension SchemaObjectRoot {
    func sortedProperties(transitive: Bool = false) -> [(Parameter, SchemaObjectProperty)] {

        let currentPairs = self.properties.map { $0 }.sorted(by: { (obj1, obj2) -> Bool in
            return obj1.0 < obj2.0
        })

        if transitive, let parentSchema = self.extends.flatMap({ $0.force() }) {
            switch parentSchema {
            case .object(let root):
                return root.sortedProperties(transitive: transitive) + currentPairs
            default:
                // This state should be invalid but need to look into it.
                return []
            }
        } else {
            return currentPairs
        }
    }
}

extension FileRenderer {
    var className: String {
        return self.rootSchema.className(with: self.params)
    }

    var parentDescriptor: Schema? {
        return self.rootSchema.extends.flatMap { $0.force() }
    }

    var transitiveProperties: [(Parameter, SchemaObjectProperty)] {
        return self.rootSchema.sortedProperties(transitive: true)
    }

    var properties: [(Parameter, SchemaObjectProperty)] {
        return self.rootSchema.sortedProperties()
    }

    var isBaseClass: Bool {
        return rootSchema.extends == nil
    }

    func resolveClassName(_ schema: Schema?) -> String? {
        switch schema {
        case .some(.object(let root)):
            return root.className(with: self.params)
        case .some(.reference(with: let ref)):
            return resolveClassName(ref.force())
        default:
            return nil
        }
    }

    fileprivate func referencedClassNames(schema: Schema) -> [String] {
        switch schema {
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(_)):
                return [typeFromSchema("", schema.nonnullProperty())]
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        case .object(let schemaRoot):
            return [schemaRoot.className(with: self.params)]
        case .map(valueType: .some(let valueType)):
            return referencedClassNames(schema: valueType)
        case .array(itemType: .some(let itemType)), .set(itemType: .some(let itemType)):
            return referencedClassNames(schema: itemType)
        case .oneOf(types: let itemTypes):
            return itemTypes.flatMap(referencedClassNames)
        default:
            return []
        }
    }

    func renderReferencedClasses() -> Set<String> {
        return Set(rootSchema.properties.values.map { $0.schema }.flatMap(referencedClassNames))
    }
}

// Currently not usable until upgrading the Swift Toolchain on CI
//extension Dictionary where Key == GenerationParameterType, Value == String {
//    func indent(file: FileGenerator) -> Int {
//        // Check if the GenerationParameters have an indentation set on it else just use the file indent
//        let indent: Int? = self[.indent].flatMap { Int($0) }
//        return indent ?? file.indent
//    }
//}

// Workaround until we can use the version from above
extension Dictionary where Value: ExpressibleByStringLiteral {
    // Check if the GenerationParameters have an indentation set on it else just use the file indent
    func indent(file: FileGenerator) -> Int {
        let key: Key? = GenerationParameterType.indent as? Key
        let indentFlag: String? = key.flatMap { self[$0] as? String }
        let indent: Int? = indentFlag.flatMap { Int($0) }
        return indent ?? file.indent
    }
}

extension FileGenerator {

    func renderCommentHeader() -> String {
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "MM-dd-yyyy 'at' HH:mm:ss"

        var copy = self

        let header = [
            "//",
            "// \(copy.fileName)",
            "// Autogenerated by plank",
            "//",
            "// DO NOT EDIT - EDITS WILL BE OVERWRITTEN",
            "// @generated",
            "//"
        ]

        return header.joined(separator: "\n")
    }
}

extension FileGeneratorManager {
    func generateFile(_ schema: SchemaObjectRoot, outputDirectory: URL, generationParameters: GenerationParameters) {
        Self.filesToGenerate(descriptor: schema, generatorParameters: generationParameters).forEach {
            writeFile(file: $0, outputDirectory: outputDirectory, generationParameters: generationParameters)
        }
    }

    public func generateFileRuntime(outputDirectory: URL, generationParameters: GenerationParameters) {
        Self.runtimeFiles().forEach {
            writeFile(file: $0, outputDirectory: outputDirectory, generationParameters: generationParameters)
        }
    }
}

func generator(forLanguage language: Languages) -> FileGeneratorManager {
    switch language {
    case .objectiveC:
        return ObjectiveCFileGenerator()
    case .flowtype:
        return JSFileGenerator()
    case .java:
        return JavaGeneratorManager()
    }
}

public func generateRuntimeFiles(outputDirectory: URL, generationParameters: GenerationParameters, forLanguages languages: [Languages]) {
    let fileGenerators: [FileGeneratorManager] = languages.map(generator)
    fileGenerators.forEach {
        $0.generateFileRuntime(outputDirectory: outputDirectory, generationParameters: generationParameters)
    }
}

public func writeFile(file: FileGenerator, outputDirectory: URL, generationParameters: GenerationParameters) {
    var file = file
    let indent = generationParameters.indent(file: file)
    let indentSpaces = String(repeating: " ", count: indent)
    let fileContents = file.renderFile()
                           .replacingOccurrences(of: "\t", with: indentSpaces)
                           .appending("\n") // Ensure there is exactly one new line a the end of the file
    do {
        try fileContents.write(
            to: URL(string: file.fileName, relativeTo: outputDirectory)!,
            atomically: true,
            encoding: String.Encoding.utf8)
    } catch {
        assert(false)
    }
}

public func loadSchemasForUrls(urls: Set<URL>) -> [(URL, Schema)] {
    return urls.map { ($0, FileSchemaLoader.sharedInstance.loadSchema($0)) }
}

public func generateDeps(urls: Set<URL>) {
    let urlSchemas = loadSchemasForUrls(urls: urls)
    let deps = Set(urlSchemas.map { (url, schema) -> String in
        ([url] + schema.deps()).map { $0.path }.joined(separator: ":")
    })
    deps.forEach { dep in
        print(dep)
    }
}

public func generateFiles(urls: Set<URL>, outputDirectory: URL, generationParameters: GenerationParameters, forLanguages languages: [Languages]) {
    let fileGenerators: [FileGeneratorManager] = languages.map(generator)
    _ = loadSchemasForUrls(urls: urls)
    var processedSchemas = Set<URL>([])
    repeat {
        _ = FileSchemaLoader.sharedInstance.refs.map({ (url: URL, schema: Schema) -> Void in
            if processedSchemas.contains(url) {
                return
            }
            processedSchemas.insert(url)
            switch schema {
            case .object(let rootObject):
                fileGenerators.forEach { generator in
                    generator.generateFile(rootObject,
                                           outputDirectory: outputDirectory,
                                           generationParameters: generationParameters)
                }
            default:
                assert(false, "Incorrect Schema for root.") // TODO Better error message.
            }
        })
    } while (
        generationParameters[.recursive] != nil &&
        processedSchemas.count != FileSchemaLoader.sharedInstance.refs.keys.count)
    if generationParameters[.includeRuntime] != nil {
        fileGenerators.forEach {
            $0.generateFileRuntime(outputDirectory: outputDirectory, generationParameters: generationParameters)
        }
    }
}
