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
    case help = "help"
}

extension FlagOptions : HelpCommandOutput {
    internal static func printHelp() -> String {
        return [
            "    --\(FlagOptions.objectiveCClassPrefix.rawValue) - The prefix to add to all generated class names.",
            "    --\(FlagOptions.outputDirectory.rawValue) - The directory where generated code will be written.",
            "    --\(FlagOptions.help.rawValue) - Show this text and exit."
        ].joined(separator: "\n")
    }
}


func parseFlag(arguments: ArraySlice<String>) -> ([FlagOptions:String], ArraySlice<String>)? {
    var remainingArgs = arguments
    if remainingArgs.isEmpty == false {
        let arg = remainingArgs.removeFirst()
        var flagName: String
        var flagValue: String
        if arg.hasPrefix("--") {
            if arg.contains("=") {
                let flagComponents = arg.components(separatedBy: "=")
                assert(flagComponents.count == 2, "Error: Invalid flag declaration")
                flagName = flagComponents[0]
                flagValue = flagComponents[1]
            } else {
                flagName = arg
                if let nextArg = remainingArgs.popFirst() {
                    flagValue = nextArg
                } else {
                    flagValue = ""
                }
            }

            if let flagType = FlagOptions(rawValue: flagName.trimmingCharacters(in: CharacterSet(charactersIn: "-"))) {
                return ([flagType : flagValue], remainingArgs)
            } else {
                print("Error: Unexpected flag \(flagName) with value \(flagValue)")
                handleHelpCommand()
                exit(1)
            }
        }
    }
    return nil
}

func parseFlags(fromArguments arguments: ArraySlice<String>) -> ([FlagOptions:String], ArraySlice<String>) {
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

func handleGenerateCommand(withArguments arguments:ArraySlice<String>) {

    var generationParameters: GenerationParameters = [:]
    let (flags, args) = parseFlags(fromArguments: arguments)

    if let _ = flags[.help] {
        handleHelpCommand()
        return
    }

    let objc_class_prefix = flags[.objectiveCClassPrefix] ?? ""
    let output_dir = flags[.outputDirectory] ?? ""

    generationParameters[GenerationParameterType.classPrefix] = ""

    if objc_class_prefix.characters.count > 0 {
        generationParameters[GenerationParameterType.classPrefix] = objc_class_prefix
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
        "\(FlagOptions.printHelp())",
    ].joined(separator: "\n")

    print(helpDocs)
}


