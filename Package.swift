import PackageDescription

let package = Package(
    name: "PINModel",
    targets: [Target(name: "pinmodel", dependencies:["Core"]),
              Target(name: "Core", dependencies:[])],
    exclude: ["Utility"]
)

