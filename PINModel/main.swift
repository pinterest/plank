//
//  main.swift
//  PINModel
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

var manager = Manager()


func beginFileGeneration(_ schemaPath: String, outputDirectoryPath: String, generationParameters: GenerationParameters = [:]) {
  let baseUrl = URL(fileURLWithPath: schemaPath).standardizedFileURL
  let outputDirectory = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
  generateFilesWithInitialUrl(baseUrl, outputDirectory: outputDirectory, generationParameters: generationParameters)
}


manager.register("generate", "Generate Model Files") { argv in
    if let url = argv.shift() {
      var generationParameters: GenerationParameters = [:]

      generationParameters[GenerationParameterType.classPrefix] = ""

      if let objcClassPrefix = argv.option("objc_class_prefix") {
        generationParameters[GenerationParameterType.classPrefix] = objcClassPrefix
      }

      var outputDirectory: URL!


      if let executionPath = ProcessInfo.processInfo.environment["PWD"] {
        // What directory path is the user in when invoke pinmodel
        outputDirectory = URL(string: executionPath)
        if let outputDir = argv.option("output_dir") {
          if outputDir.hasPrefix("/") {
            // Absolute file URL
            outputDirectory = URL(string: outputDir)!
          } else {
            outputDirectory = outputDirectory.appendingPathComponent(outputDir)
          }
        }
      } else {
        // Unexpected to go in here but possible if PWD is not defined from the environment.
        let outputDirectory = URL(string: FileManager.default.currentDirectoryPath)!
      }

      beginFileGeneration(url, outputDirectoryPath: outputDirectory.absoluteString, generationParameters: generationParameters)
    } else {
        assert(false, "Missing URL to JSON-Schema")
    }
}

manager.run()
//manager.run(arguments: ["generate", "schemas/pin.json"]) // Useful for debugging
