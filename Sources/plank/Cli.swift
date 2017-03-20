//
//  Cli.swift
//  Plank
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation
import Core

func beginFileGeneration(_ schemaPaths: Set<String>, outputDirectoryPath: String, generationParameters: GenerationParameters = [:]) {
    let urls = schemaPaths.map { URL(fileURLWithPath: $0).standardizedFileURL }
    let outputDirectory = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
    generateFilesWithInitialUrl(urls: Set(urls),
                                outputDirectory: outputDirectory,
                                generationParameters: generationParameters)
}

protocol HelpCommandOutput {
    static func printHelp() -> String
}

enum FlagOptions: String {
    case outputDirectory = "output_dir"
    case objectiveCClassPrefix = "objc_class_prefix"
    case printDeps = "print_deps"
    case help = "help"

    func needsArgument() -> Bool {
        switch self {
        case .outputDirectory: return true
        case .objectiveCClassPrefix: return true
        case .printDeps: return false
        case .help: return false
        }
    }
}

extension FlagOptions : HelpCommandOutput {
    internal static func printHelp() -> String {
        return [
            "    --\(FlagOptions.objectiveCClassPrefix.rawValue) - The prefix to add to all generated class names.",
            "    --\(FlagOptions.outputDirectory.rawValue) - The directory where generated code will be written.",
            "    --\(FlagOptions.printDeps.rawValue) - Just print the path to the dependent schemas necessary to generate the schemas provided and exit.",
            "    --\(FlagOptions.help.rawValue) - Show this text and exit."
        ].joined(separator: "\n")
    }
}

func parseFlag(arguments: [String]) -> ([FlagOptions:String], [String])? {

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

func parseFlags(fromArguments arguments: [String]) -> ([FlagOptions:String], [String]) {
    guard !arguments.isEmpty else { return ([:], arguments) }

    if let (flagDict, remainingArgs) = parseFlag(arguments: arguments) {
        if remainingArgs.count > 0 {
            // recursive
            let (remainingFlags, extraArgs) = parseFlags(fromArguments: remainingArgs)
            if remainingFlags.count == 0 {
                return (flagDict, extraArgs)
            }
            var mutableFlags = flagDict
            _ = remainingFlags.map { k, v in mutableFlags.updateValue(v, forKey: k) }
            return (mutableFlags, extraArgs)
        } else {
            return (flagDict, remainingArgs)
        }
    }
    return ([:], arguments)
}

func handleGenerateCommand(withArguments arguments: [String]) {

    var generationParameters: GenerationParameters = [:]
    let (flags, args) = parseFlags(fromArguments: arguments)

    if flags[.help] != nil {
        handleHelpCommand()
        return
    }

    let objc_class_prefix = flags[.objectiveCClassPrefix] ?? ""
    let output_dir = flags[.outputDirectory] ?? ""

    generationParameters[GenerationParameterType.classPrefix] = ""

    if objc_class_prefix.characters.count > 0 {
        generationParameters[GenerationParameterType.classPrefix] = objc_class_prefix
    }
    if flags[.printDeps] != nil {
        generationParameters[GenerationParameterType.printDeps] = ""
    }

    guard !args.isEmpty else {
        print("Error: Missing or invalid URL to JSONSchema")
        handleHelpCommand()
        return
    }

    var outputDirectory: URL!

    if let executionPath = ProcessInfo.processInfo.environment["PWD"] {
        // What directory path is the user in when invoke Plank
        outputDirectory = URL(string: executionPath)
        if output_dir.characters.count > 0 {
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

    beginFileGeneration(Set(args),
                        outputDirectoryPath: outputDirectory.absoluteString,
                        generationParameters: generationParameters)
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
