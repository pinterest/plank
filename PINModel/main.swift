//
//  main.swift
//  PINModel
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

var manager = Manager()


func beginFileGeneration(schemaPath: String, outputDirectoryPath: String, generationParameters: GenerationParameters = [:]) {
  if let baseUrl = NSURL(fileURLWithPath: schemaPath).URLByStandardizingPath {
    let outputDirectory = NSURL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
    generateFilesWithInitialUrl(baseUrl, outputDirectory: outputDirectory, generationParameters: generationParameters)
  } else {
    assert(false, "Cannot load schema from this URL")
  }
}


manager.register("generate", "Generate Model Files") { argv in
    if let url = argv.shift() {
      var generationParameters: GenerationParameters = [:]

      generationParameters[GenerationParameterType.ClassPrefix] = ""

      if let objcClassPrefix = argv.option("objc_class_prefix") {
        generationParameters[GenerationParameterType.ClassPrefix] = objcClassPrefix
      }

      var outputDirectory: NSURL!

      if let executionPath = NSProcessInfo.processInfo().environment["PWD"] {
        // Where did the user invoke pinmodel from
        outputDirectory = NSURL(string: executionPath)!
        if let outputDir = argv.option("output_dir") {
          if outputDir.hasPrefix("/") {
            // Absolute file URL
            outputDirectory = NSURL(string: outputDir)!
          } else {
            outputDirectory = outputDirectory.URLByAppendingPathComponent(outputDir)
          }
        }
      } else {
        // Unexpected to go in here but possible if PWD is not defined from the environment.
        let outputDirectory = NSURL(string: NSFileManager.defaultManager().currentDirectoryPath)!
      }

      beginFileGeneration(url, outputDirectoryPath: outputDirectory.absoluteString!, generationParameters: generationParameters)
    } else {
        assert(false, "Missing URL to JSON-Schema")
    }
}

manager.run()
//manager.run(arguments: ["generate", "schemas/pin.json"]) // Useful for debugging
