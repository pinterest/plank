load("@build_bazel_rules_apple//apple:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")

swift_library(
    name = "PlankCore",
    srcs = glob(["Sources/Core/*.swift"]),
    module_name = "Core",
    swift_version = 4,
    copts = ["-whole-module-optimization"]
)

swift_library(
    name = "PlankLib",
    srcs = glob(["Sources/plank/*.swift"]),
    swift_version = 4,
    copts = ["-whole-module-optimization"],
    deps = [":PlankCore"]
)

macos_command_line_application(
    name = "plank",
    deps = [":PlankLib"]
)
