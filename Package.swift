// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "plank",
    targets: [
        .target(name: "plank", dependencies:["Core"], exclude: ["Utility", "Examples"]),
        .target(name: "Core", dependencies:[], exclude: ["Utility",
        "Examples"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"])
    ]
)

