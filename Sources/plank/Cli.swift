//
//  Cli.swift
//  Plank
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Core
import Foundation

protocol HelpCommandOutput {
    static func printHelp() -> String
}

enum FlagOptions: String {
    case outputDirectory = "output_dir"
    case objectiveCClassPrefix = "objc_class_prefix"
    case javaPackageName = "java_package_name"
    case javaNullabilityAnnotationType = "java_nullability_annotation_type"
    case javaExtends = "java_extends"
    case javaImplements = "java_implements"
    case printDeps = "print_deps"
    case noRecursive = "no_recursive"
    case noRuntime = "no_runtime"
    case onlyRuntime = "only_runtime"
    case indent
    case lang
    case help
    case version

    func needsArgument() -> Bool {
        switch self {
        case .outputDirectory: return true
        case .objectiveCClassPrefix: return true
        case .indent: return true
        case .printDeps: return false
        case .noRecursive: return false
        case .noRuntime: return false
        case .onlyRuntime: return false
        case .lang: return true
        case .help: return false
        case .version: return false
        case .javaPackageName: return true
        case .javaNullabilityAnnotationType: return true
        case .javaExtends: return true
        case .javaImplements: return true
        }
    }
}

extension FlagOptions: HelpCommandOutput {
    internal static func printHelp() -> String {
        return [
            "    --\(FlagOptions.outputDirectory.rawValue) - The directory where generated code will be written",
            "    --\(FlagOptions.printDeps.rawValue) - Just print the path to the dependent schemas necessary to generate the schemas provided and exit",
            "    --\(FlagOptions.noRecursive.rawValue) - Don't generate files recursively. Only generate the one file I ask for",
            "    --\(FlagOptions.noRuntime.rawValue) - Don't generate runtime files",
            "    --\(FlagOptions.onlyRuntime.rawValue) - Only generate runtime files and exit",
            "    --\(FlagOptions.indent.rawValue) - Define a custom indentation",
            "    --\(FlagOptions.lang.rawValue) - Comma separated list of target language(s) for generating code. Default: \"objc\"",
            "    --\(FlagOptions.help.rawValue) - Show this text and exit",
            "    --\(FlagOptions.version.rawValue) - Show version number and exit",
            "",
            "    Objective-C:",
            "    --\(FlagOptions.objectiveCClassPrefix.rawValue) - The prefix to add to all generated class names",
            "",
            "    Java:",
            "    --\(FlagOptions.javaPackageName.rawValue) - The package name to associate with generated Java sources",
            "    --\(FlagOptions.javaNullabilityAnnotationType.rawValue) - The type of nullability annotations to use. Can be either \"android-support\" (default) or \"androidx\".",
            "    --\(FlagOptions.javaExtends.rawValue) - The class that the model extends",
            "    --\(FlagOptions.javaImplements.rawValue) - The interface(s) that the model implements. If there are multiple interfaces, separate with commas.",
        ].joined(separator: "\n")
    }
}

func parseFlag(arguments: [String]) -> ([FlagOptions: String], [String])? {
    guard let someFlag = (arguments.first.map {
        $0.components(separatedBy: "=")[0]
    }.flatMap { arg in
        arg.hasPrefix("--") ? arg.trimmingCharacters(in: CharacterSet(charactersIn: "-")) : nil
    }) else { return nil }

    guard let nextFlag = FlagOptions(rawValue: someFlag) else {
        print("Error: Unexpected flag \(someFlag)")
        handleHelpCommand()
        exit(1)
    }

    if nextFlag.needsArgument() {
        let arg = arguments[0]
        if arg.contains("=") {
            let flagComponents = arg.components(separatedBy: "=")
            assert(flagComponents.count == 2, "Error: Invalid flag declaration: Too many = signs")
            return (
                [nextFlag: flagComponents[1]],
                Array(arguments[1 ..< arguments.count])
            )
        } else {
            assert(arguments.count >= 2, "Error: Invalid flag declaration: No value for \(nextFlag.rawValue)")
            return (
                [nextFlag: arguments[1]],
                Array(arguments[2 ..< arguments.count])
            )
        }
    } else {
        return (
            [nextFlag: ""],
            Array(arguments[1 ..< arguments.count])
        )
    }
}

func parseFlags(fromArguments arguments: [String]) -> ([FlagOptions: String], [String]) {
    guard !arguments.isEmpty else { return ([:], arguments) }

    if let (flagDict, remainingArgs) = parseFlag(arguments: arguments) {
        if !remainingArgs.isEmpty {
            // recursive
            let (remainingFlags, extraArgs) = parseFlags(fromArguments: remainingArgs)
            if remainingFlags.isEmpty {
                return (flagDict, extraArgs)
            }
            var mutableFlags = flagDict
            _ = remainingFlags.map { key, value in mutableFlags.updateValue(value, forKey: key) }
            return (mutableFlags, extraArgs)
        } else {
            return (flagDict, remainingArgs)
        }
    }
    return ([:], arguments)
}

func handleGenerateCommand(withArguments arguments: [String]) {
    let (flags, args) = parseFlags(fromArguments: arguments)

    if flags[.help] != nil {
        handleHelpCommand()
        return
    }

    if flags[.version] != nil {
        handleVersionCommand()
        return
    }

    let outputDirectoryArg = flags[.outputDirectory] ?? ""

    // defaults
    // need to be lifted out of literal because https://bugs.swift.org/browse/SR-2372
    let recursive: String? = (flags[.noRecursive] == nil) ? .some("") : .none
    let classPrefix: String? = flags[.objectiveCClassPrefix]
    let includeRuntime: String? = flags[.onlyRuntime] != nil || (flags[.noRuntime] == nil || flags[.noRecursive] != nil) ? .some("") : .none
    let indent: String? = flags[.indent]
    let packageName: String? = flags[.javaPackageName]
    let javaNullabilityAnnotationType: String? = flags[.javaNullabilityAnnotationType]
    let javaExtends: String? = flags[.javaExtends]
    let javaImplements: String? = flags[.javaImplements]

    let generationParameters: GenerationParameters = [
        (.recursive, recursive),
        (.classPrefix, classPrefix),
        (.includeRuntime, includeRuntime),
        (.indent, indent),
        (.packageName, packageName),
        (.javaNullabilityAnnotationType, javaNullabilityAnnotationType),
        (.javaExtends, javaExtends),
        (.javaImplements, javaImplements),
    ].reduce([:]) { (dict: GenerationParameters, tuple: (GenerationParameterType, String?)) in
        var mutableDict = dict
        if let val = tuple.1 {
            mutableDict[tuple.0] = val
        }
        return mutableDict
    }

    guard !args.isEmpty || flags[.onlyRuntime] != nil else {
        print("Error: Missing or invalid URL to JSONSchema")
        handleHelpCommand()
        return
    }

    var outputDirectory: URL!

    if let executionPath = ProcessInfo.processInfo.environment["PWD"] {
        // What directory path is the user in when invoke Plank
        outputDirectory = URL(string: executionPath)
        if !outputDirectoryArg.isEmpty {
            if outputDirectoryArg.hasPrefix("/") {
                // Absolute file URL
                outputDirectory = URL(string: outputDirectoryArg)!
            } else {
                outputDirectory = outputDirectory.appendingPathComponent(outputDirectoryArg)
            }
        }
    } else {
        // Unexpected to go in here but possible if PWD is not defined from the environment.
        outputDirectory = URL(string: FileManager.default.currentDirectoryPath)!
    }
    outputDirectory = URL(fileURLWithPath: outputDirectory.absoluteString, isDirectory: true)

    let urls = args.map { URL(string: $0)! }
    let languages: [Languages] = flags[.lang]?.trimmingCharacters(in: .whitespaces).components(separatedBy: ",").compactMap {
        guard let lang = Languages(rawValue: $0) else {
            fatalError("Invalid or unsupported language: \($0)")
        }
        return lang
    } ?? [.objectiveC]
    guard !languages.isEmpty else {
        fatalError("Unsupported value for lang: \"\(String(describing: flags[.lang]))\"")
    }

    if flags[.printDeps] != nil {
        generateDeps(urls: Set(urls))
    } else if flags[.onlyRuntime] != nil {
        generateRuntimeFiles(outputDirectory: outputDirectory,
                             generationParameters: generationParameters,
                             forLanguages: languages)
    } else {
        generateFiles(urls: Set(urls),
                      outputDirectory: outputDirectory,
                      generationParameters: generationParameters,
                      forLanguages: languages)
    }
}

func handleHelpCommand() {
    let helpDocs = [
        "Usage:",
        "    $ plank [options] file1 file2 ...",
        "",
        "Options:",
        "\(FlagOptions.printHelp())",
    ].joined(separator: "\n")

    print(helpDocs)
}

func handleVersionCommand() {
    print(Version.current.value)
}
