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
    handleGenerateCommand(withArguments: arguments)
}

handleProcess(processInfo: ProcessInfo.processInfo)

