// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "plank",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.39.3"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.30.1"),
    ],

    targets: [
        .target(name: "plank", dependencies: ["Core"], exclude: ["Utility", "Examples"]),
        .target(name: "Core", dependencies: [], exclude: ["Utility",
                                                          "Examples"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
