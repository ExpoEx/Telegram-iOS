load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SnapKit",
    module_name = "SnapKit",
    srcs = glob([
		"snap_kit/Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
    ],
    visibility = [
        "//visibility:public",
    ],
)
