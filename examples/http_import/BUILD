load("//:defs.bzl", "dhall_json", "dhall_library", "dhall_prelude", "dhall_yaml")

package(default_visibility = ["//visibility:public"])

dhall_prelude(name = "prelude")

dhall_library(
    name = "false",
    entrypoint = "false.dhall",
    tags = ["block-network"],
    deps = [
        ":prelude",
    ],
)

dhall_yaml(
    name = "false_yaml",
    entrypoint = "false.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":prelude",
    ],
)

dhall_json(
    name = "false_json",
    entrypoint = "false.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":prelude",
    ],
)
