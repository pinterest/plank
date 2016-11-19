//
//  main.swift
//  PINModel
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

func beginFileGeneration(_ schemaPath: String, outputDirectoryPath: String, generationParameters: GenerationParameters = [:]) {
  let baseUrl = URL(fileURLWithPath: schemaPath).standardizedFileURL
  let outputDirectory = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
  generateFilesWithInitialUrl(baseUrl, outputDirectory: outputDirectory, generationParameters: generationParameters)
}

enum CommandOptions: String {
    case Generate = "generate"
    case Help = "help"
}

enum FlagOptions: String {
    case OutputDirectory = "output_dir"
    case ObjectiveCClassPrefix = "objc_class_prefix"
}

func handleProcess(processInfo: ProcessInfo) {
    let arguments = ProcessInfo.processInfo.arguments.dropFirst() // Drop executable name
    if let command = CommandOptions(rawValue: arguments.first ?? "") {
        switch command {
        case CommandOptions.Generate:
            handleGenerateCommand(withArguments: arguments.dropFirst())
            break
        case CommandOptions.Help:
            handleHelpCommand()
            break
        }

    } else {
        print("Error: Unrecognized command: \(arguments.first!)")
        handleHelpCommand() // Print help information when we reach a command we don't understand
    }
}

func parseFlags(fromArguments arguments:ArraySlice<String>) -> [FlagOptions:String] {
    var trimmedArgs = arguments.flatMap { (arg) -> String? in
        let formattedArg = arg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) // Remove leading / trailing whitespace
                  .trimmingCharacters(in: CharacterSet(charactersIn: "-")) // Remove arguments prefixed with "--"
        if formattedArg == "" {
            return nil
        }
        return formattedArg
    }

    var flags: [FlagOptions:String] = [:]

    while !trimmedArgs.isEmpty {
        let arg = trimmedArgs.removeFirst()
        var flagName: String
        var flagValue: String
        if arg.contains("=") {
            let flagComponents = arg.components(separatedBy: "=")
            assert(flagComponents.count == 2, "Error: Invalid flag declaration")
            flagName = flagComponents[0]
            flagValue = flagComponents[1]
        } else {
            flagName = arg
            flagValue = trimmedArgs.removeFirst()
        }

        if let flagType = FlagOptions(rawValue: flagName) {
            flags[flagType] = flagValue
        } else {
            assert(false, "Unexpected flag \(flagName) with value \(flagValue)")
        }
    }
    return flags
}

func handleGenerateCommand(withArguments arguments:ArraySlice<String>) {
    let url = arguments.first ?? ""
    if url.characters.count == 0 {
        print("Error: Missing or invalid URL to JSONSchema")
        handleHelpCommand()
        return
    }

    var generationParameters: GenerationParameters = [:]
    let flags = parseFlags(fromArguments: arguments.dropFirst())

    let objc_class_prefix = flags[.ObjectiveCClassPrefix] ?? ""
    let output_dir = flags[.OutputDirectory] ?? ""

    generationParameters[GenerationParameterType.classPrefix] = ""

    if objc_class_prefix.characters.count > 0 {
        generationParameters[GenerationParameterType.classPrefix] = objc_class_prefix
    }

    var outputDirectory: URL!

    if let executionPath = ProcessInfo.processInfo.environment["PWD"] {
        // What directory path is the user in when invoke pinmodel
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

    beginFileGeneration(url, outputDirectoryPath: outputDirectory.absoluteString, generationParameters: generationParameters)
}

func handleHelpCommand() {
    let helpDocs = [
        "Usage:",
        "    $ pinmodel [command] [options]",
        "",
        "Commands:",
        "    \(CommandOptions.Generate.rawValue) - Generates immutable model and utilities code for the schema at the url",
        "    \(CommandOptions.Help.rawValue) - Print help information",
        "",
        "Options:",
        "    --\(FlagOptions.ObjectiveCClassPrefix.rawValue) - The prefix to add to all generated class names (i.e. \"PIN\" for \"PINModel\")",
        "    --\(FlagOptions.OutputDirectory.rawValue) - The directory where generated code will be written",
    ].joined(separator: "\n")

    print(helpDocs)
}

handleProcess(processInfo: ProcessInfo.processInfo)

