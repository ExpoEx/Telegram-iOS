load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TGTools",
    module_name = "TGTools",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
    ],
    deps = [
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/AccountContext:AccountContext",
        "//third-party/SnapKit:SnapKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
