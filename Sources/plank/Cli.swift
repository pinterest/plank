//
//  Cli.swift
//  Plank
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation
import Core

protocol HelpCommandOutput {
    static func printHelp() -> String
}

enum FlagOptions: String {
    case outputDirectory = "output_dir"
    case objectiveCClassPrefix = "objc_class_prefix"
    case javaPackageName = "java_package_name"
    case printDeps = "print_deps"
    case noRecursive = "no_recursive"
    case onlyRuntime = "only_runtime"
    case indent = "indent"
    case lang = "lang"
    case help = "help"

    func needsArgument() -> Bool {
        switch self {
        case .outputDirectory: return true
        case .objectiveCClassPrefix: return true
        case .indent: return true
        case .printDeps: return false
        case .noRecursive: return false
        case .onlyRuntime: return false
        case .lang: return true
        case .help: return false
        case .javaPackageName: return true
        }
    }
}

extension FlagOptions: HelpCommandOutput {
    internal static func printHelp() -> String {
        return [
            "    --\(FlagOptions.outputDirectory.rawValue) - The directory where generated code will be written",
            "    --\(FlagOptions.printDeps.rawValue) - Just print the path to the dependent schemas necessary to generate the schemas provided and exit",
            "    --\(FlagOptions.noRecursive.rawValue) - Don't generate files recursively. Only generate the one file I ask for",
            "    --\(FlagOptions.onlyRuntime.rawValue) - Only generate runtime files and exit",
            "    --\(FlagOptions.indent.rawValue) - Define a custom indentation",
            "    --\(FlagOptions.lang.rawValue) - Comma separated list of target language(s) for generating code. Default: \"objc\"",
            "    --\(FlagOptions.help.rawValue) - Show this text and exit",
            "",
            "    Objective-C:",
            "    --\(FlagOptions.objectiveCClassPrefix.rawValue) - The prefix to add to all generated class names",
            "",
            "    Java:",
            "    --\(FlagOptions.javaPackageName.rawValue) - The package name to associate with generated Java sources"
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
                Array(arguments[1..<arguments.count])
            )
        } else {
            assert(arguments.count >= 2, "Error: Invalid flag declaration: No value for \(nextFlag.rawValue)")
            return (
                [nextFlag: arguments[1]],
                Array(arguments[2..<arguments.count])
            )
        }
    } else {
        return (
            [nextFlag: ""],
            Array(arguments[1..<arguments.count])
        )
    }
}

func parseFlags(fromArguments arguments: [String]) -> ([FlagOptions: String], [String]) {
    guard !arguments.isEmpty else { return ([:], arguments) }

    if let (flagDict, remainingArgs) = parseFlag(arguments: arguments) {
        if remainingArgs.count > 0 {
            // recursive
            let (remainingFlags, extraArgs) = parseFlags(fromArguments: remainingArgs)
            if remainingFlags.count == 0 {
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

    let output_dir = flags[.outputDirectory] ?? ""

    // defaults
    // need to be lifted out of literal because https://bugs.swift.org/browse/SR-2372
    let recursive: String? = (flags[.noRecursive] == nil) ? .some("") : .none
    let classPrefix: String? = flags[.objectiveCClassPrefix]
    let includeRuntime: String? = flags[.onlyRuntime] != nil || flags[.noRecursive] == nil ? .some("") : .none
    let indent: String? = flags[.indent]
    let packageName: String? = flags[.javaPackageName]

    let generationParameters: GenerationParameters = [
        (.recursive, recursive),
        (.classPrefix, classPrefix),
        (.includeRuntime, includeRuntime),
        (.indent, indent),
        (.packageName, packageName)
    ].reduce([:]) { (dict: GenerationParameters, tuple: (GenerationParameterType, String?)) in
            var d = dict
            if let v = tuple.1 {
                d[tuple.0] = v
            }
            return d
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
        if output_dir.count > 0 {
            if output_dir.hasPrefix("/") {
                // Absolute file URL
                outputDirectory = URL(string: output_dir)!
            } else {
                outputDirectory = outputDirectory.appendingPathComponent(output_dir)
            }
        }
    } else {
        // Unexpected to go in here but possible if PWD is not defined from the environment.
        outputDirectory = URL(string: FileManager.default.currentDirectoryPath)!
    }
    outputDirectory = URL(fileURLWithPath: outputDirectory.absoluteString, isDirectory: true)

    let urls = args.map { URL(string: $0)! }
    let languages: [Languages] = flags[.lang]?.trimmingCharacters(in: .whitespaces).components(separatedBy: ",").flatMap {
        guard let lang = Languages.init(rawValue: $0) else {
            fatalError("Invalid or unsupported language: \($0)")
        }
        return lang
        } ?? [.objectiveC]
    guard languages.count > 0 else {
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
        "\(FlagOptions.printHelp())"
    ].joined(separator: "\n")

    print(helpDocs)
}
