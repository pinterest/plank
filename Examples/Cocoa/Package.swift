// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Objective_C",
    targets: [
        .target(name: "Objective_C"),
        .testTarget(name: "Objective_CTests", dependencies: ["Objective_C"]),
    ]
)
