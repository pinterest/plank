//
//  main.swift
//  PINModel
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

import Commander

func beginFileGeneration(_ schemaPath: String, outputDirectoryPath: String, generationParameters: GenerationParameters = [:]) {
  let baseUrl = URL(fileURLWithPath: schemaPath).standardizedFileURL
  let outputDirectory = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
  generateFilesWithInitialUrl(baseUrl, outputDirectory: outputDirectory, generationParameters: generationParameters)
}

Group {
  $0.command("generate",
    Argument<String>("url"),
    Option("output_dir", "", description: "Relative path where file will be written"),
    Option("objc_class_prefix", "", description: "Prefix that will be used to prepend types generated for Objective-C files"),
    description: "Generates immutable model and utilities code for the schema at the url"
  ) { (url:String, output_dir:String, objc_class_prefix:String) in
    if url.characters.count > 0 {
      var generationParameters: GenerationParameters = [:]

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
        let outputDirectory = URL(string: FileManager.default.currentDirectoryPath)!
      }

      beginFileGeneration(url, outputDirectoryPath: outputDirectory.absoluteString, generationParameters: generationParameters)
    } else {
        assert(false, "Missing URL to JSONSchema")
    }
  }
}.run()

