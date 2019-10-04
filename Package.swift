// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "plank",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.40.12"),
        .package(url: "https://github.com/realm/SwiftLint.git", .revision("2dcaf3ee7803e25c8163e2fbbb9b8ac2be722a2d")),
    ],

    targets: [
        .target(name: "plank", dependencies: ["Core"], exclude: ["Utility", "Examples"]),
        .target(name: "Core", dependencies: [], exclude: ["Utility",
                                                          "Examples"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
