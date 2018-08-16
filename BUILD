load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_binary")


swift_library(
    name = "PlankCore",
    srcs = glob(["Sources/Core/*.swift"]),
    module_name = "Core",
    copts = ["-whole-module-optimization"]
)

swift_library(
    name = "PlankLib",
    srcs = glob(["Sources/plank/*.swift"]),
    copts = ["-whole-module-optimization"],
    deps = [":PlankCore"]
)

swift_binary(
    name = "plank",
    deps = [":PlankLib"]
)
