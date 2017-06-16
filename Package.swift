// swift-tools-version:3.1

import PackageDescription
import Foundation

// HACK from https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Package.swift
var isSwiftPMTest: Bool {
    return ProcessInfo.processInfo.environment["SWIFTPM_TEST_Plank"] == "YES"
}

let package = Package(
    name: "plank",
    targets: [Target(name: "plank", dependencies:["Core"]),
              Target(name: "Core", dependencies:[])],
    dependencies: isSwiftPMTest ?
                [.Package(url: "https://github.com/typelift/SwiftCheck.git", versions: Version(0,6,0)..<Version(1,0,0))] : [],
    exclude: ["Utility", "Examples"]
)

