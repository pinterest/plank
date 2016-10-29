import PackageDescription

let package = Package(
    name: "pinmodel",
    dependencies: [
        // Commander framework is used for type-safe command line argument parsing.
        .Package(url: "https://github.com/kylef/Commander", majorVersion: 0, minor: 5),
    ]
)
