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
    case javaNullabilityAnnotationType
    case javaExtends
    case javaImplements
}

// Most of these are derived from https://www.binpress.com/tutorial/objective-c-reserved-keywords/43
// other language conflicts should be ideally added here.
// TODO: Find a way to separate this by language since the reserved keywords will differ.
let objectiveCReservedWordReplacements = [
    "description": "description_text",
    "id": "identifier",
]

let objectiveCReservedWords = Set<String>([
    "@catch()",
    "@class",
    "@dynamic",
    "@end",
    "@finally",
    "@implementation",
    "@interface",
    "@private",
    "@property",
    "@protected",
    "@protocol",
    "@public",
    "@selector",
    "@synthesize",
    "@throw",
    "@try",
    "BOOL",
    "Class",
    "IMP",
    "NO",
    "NULL",
    "Protocol",
    "SEL",
    "YES",
    "_Bool",
    "_Complex",
    "_Imaginery",
    "atomic",
    "auto",
    "break",
    "bycopy",
    "byref",
    "case",
    "char",
    "const",
    "continue",
    "default",
    "do",
    "double",
    "else",
    "enum",
    "extern",
    "float",
    "for",
    "goto",
    "id",
    "if",
    "in",
    "inline",
    "inout",
    "int",
    "long",
    "nil",
    "nonatomic",
    "oneway",
    "out",
    "register",
    "restrict",
    "retain",
    "return",
    "self",
    "short",
    "signed",
    "sizeof",
    "static",
    "struct",
    "super",
    "switch",
    "typedef",
    "union",
    "unsigned",
    "void",
    "volatile",
    "while",
])

// TODO: "id" is technically allowed. It's possible not everyone wants this replacement.
let javaReservedWordReplacements = [
    "id": "uid",
]

// https://en.wikipedia.org/wiki/List_of_Java_keywords
let javaReservedWords = Set<String>([
    "abstract",
    "assert",
    "boolean",
    "break",
    "byte",
    "case",
    "catch",
    "char",
    "class",
    "continue",
    "default",
    "do",
    "double",
    "else",
    "enum",
    "exports",
    "extends",
    "final",
    "finally",
    "float",
    "for",
    "if",
    "implements",
    "import",
    "instanceof",
    "int",
    "interface",
    "long",
    "module",
    "native",
    "new",
    "package",
    "private",
    "protected",
    "public",
    "requires",
    "return",
    "short",
    "static",
    "strictfp",
    "super",
    "switch",
    "synchronized",
    "this",
    "throw",
    "throws",
    "transient",
    "try",
    "void",
    "volatile",
    "while",
    "true",
    "null",
    "false",
    "var",
    "const",
    "goto",
])

public enum Languages: String {
    case objectiveC = "objc"
    case flowtype = "flow"
    case java

    func snakeCaseToCamelCase(_ param: String) -> String {
        var str: String = param

        switch self {
        case .objectiveC:
            if let replacementString = objectiveCReservedWordReplacements[param.lowercased()] as String? {
                str = replacementString
            }
        case .java:
            if let replacementString = javaReservedWordReplacements[param.lowercased()] as String? {
                str = replacementString
            }
        case .flowtype:
            break
        }

        let components = str.components(separatedBy: "_")
        let name = components.map { $0.uppercaseFirst }
        let formattedName = name.joined(separator: "")
        switch self {
        case .objectiveC:
            if objectiveCReservedWords.contains(formattedName) {
                return "\(formattedName)Property"
            }
        case .java:
            if javaReservedWords.contains(formattedName) {
                return "\(formattedName)Property"
            }
        case .flowtype:
            break
        }

        return formattedName
    }

    /// All components separated by _ will be capitalized execpt the first
    func snakeCaseToPropertyName(_ param: String) -> String {
        var str: String = param

        switch self {
        case .objectiveC:
            if let replacementString = objectiveCReservedWordReplacements[param.lowercased()] as String? {
                str = replacementString
            }
        case .java:
            if let replacementString = javaReservedWordReplacements[param.lowercased()] as String? {
                str = replacementString
            }
        case .flowtype:
            break
        }

        let components = str.components(separatedBy: "_")

        var name: String = ""

        for (idx, component) in components.enumerated() {
            // Hack: Force URL's to be uppercase if they appear
            if idx != 0, components.count > 1, component == "url" {
                name += component.uppercased()
                continue
            }

            if idx != 0 {
                name += component.uppercaseFirst
            } else {
                name += component.lowercaseFirst
            }
        }

        switch self {
        case .objectiveC:
            if objectiveCReservedWords.contains(name) {
                return "\(name)Property"
            }
        case .java:
            if javaReservedWords.contains(name) {
                return "\(name)Property"
            }
        case .flowtype:
            break
        }

        return name
    }

    func snakeCaseToCapitalizedPropertyName(_ param: String) -> String {
        let formattedPropName = snakeCaseToPropertyName(param)
        let capitalizedFirstLetter = String(formattedPropName[formattedPropName.startIndex]).uppercased()
        return capitalizedFirstLetter + String(formattedPropName.dropFirst())
    }
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
        let currentPairs = properties.map { $0 }.sorted(by: { (obj1, obj2) -> Bool in
            obj1.0 < obj2.0
        })

        if transitive, let parentSchema = self.extends.flatMap({ $0.force() }) {
            switch parentSchema {
            case let .object(root):
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
        return rootSchema.className(with: params)
    }

    var parentDescriptor: Schema? {
        return rootSchema.extends.flatMap { $0.force() }
    }

    var transitiveProperties: [(Parameter, SchemaObjectProperty)] {
        return rootSchema.sortedProperties(transitive: true)
    }

    var properties: [(Parameter, SchemaObjectProperty)] {
        return rootSchema.sortedProperties()
    }

    var isBaseClass: Bool {
        return rootSchema.extends == nil
    }

    func resolveClassName(_ schema: Schema?) -> String? {
        switch schema {
        case let .some(.object(root)):
            return root.className(with: params)
        case let .some(.reference(with: ref)):
            return resolveClassName(ref.force())
        default:
            return nil
        }
    }

    fileprivate func referencedClassNames(schema: Schema) -> [String] {
        switch schema {
        case let .reference(with: ref):
            switch ref.force() {
            case .some(.object):
                return [typeFromSchema("", schema.nonnullProperty())]
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        case let .object(schemaRoot):
            return [schemaRoot.className(with: self.params)]
        case let .map(valueType: .some(valueType)):
            return referencedClassNames(schema: valueType)
        case let .array(itemType: .some(itemType)), let .set(itemType: .some(itemType)):
            return referencedClassNames(schema: itemType)
        case let .oneOf(types: itemTypes):
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
// extension Dictionary where Key == GenerationParameterType, Value == String {
//    func indent(file: FileGenerator) -> Int {
//        // Check if the GenerationParameters have an indentation set on it else just use the file indent
//        let indent: Int? = self[.indent].flatMap { Int($0) }
//        return indent ?? file.indent
//    }
// }

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
            "//",
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
            encoding: String.Encoding.utf8
        )
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
            case let .object(rootObject):
                fileGenerators.forEach { generator in
                    generator.generateFile(rootObject,
                                           outputDirectory: outputDirectory,
                                           generationParameters: generationParameters)
                }
            default:
                assert(false, "Incorrect Schema for root.") // TODO: Better error message.
            }
        })
    } while
        generationParameters[.recursive] != nil && processedSchemas.count != FileSchemaLoader.sharedInstance.refs.keys.count
    if generationParameters[.includeRuntime] != nil {
        fileGenerators.forEach {
            $0.generateFileRuntime(outputDirectory: outputDirectory, generationParameters: generationParameters)
        }
    }
}
