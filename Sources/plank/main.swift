//
//  main.swift
//  Plank
//
//  Created by Rahul Malik on 7/22/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

func handleProcess(processInfo: ProcessInfo) {
    let arguments = processInfo.arguments.dropFirst() // Drop executable name
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
        if let firstArg = arguments.first {
            print("Unrecognized command: \(firstArg)\n")
        }
        handleHelpCommand() // Print help information when we reach a command we don't understand
    }
}

handleProcess(processInfo: ProcessInfo.processInfo)

