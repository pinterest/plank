import PackageDescription

let package = Package(
    name: "plank",
    targets: [Target(name: "plank", dependencies:["Core"]),
              Target(name: "Core", dependencies:[])],
    exclude: ["Utility", "Examples"]
)

