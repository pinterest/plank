load('@bazel_tools//tools/build_defs/repo:git.bzl', system_git_repository='git_repository')

# Apple platform dependencies

system_git_repository(
    name = "build_bazel_rules_apple",
    remote = "https://github.com/bazelbuild/rules_apple.git",
    tag = "0.16.1",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

system_git_repository(
    name = "build_bazel_rules_swift",
    remote = "https://github.com/bazelbuild/rules_swift.git",
    tag = "0.6.0",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

# Java / Android dependencies

android_sdk_repository(
    name = "androidsdk",
)

maven_server(
    name = "google_maven",
    url = "https://maven.google.com"
)

maven_jar(
    name = "gson_maven",
    artifact = "com.google.code.gson:gson:2.8.5",
)

bind(
    name = "gson",
    actual = "@gson_maven//jar",
)

maven_jar(
    name = "android_support_annotations",
    artifact = "com.android.support:support-annotations:28.0.0",
    server = "google_maven"
)

maven_jar(
    name = "androidx_annotations",
    artifact = "androidx.annotation:annotation:1.0.2",
    server = "google_maven"
)
