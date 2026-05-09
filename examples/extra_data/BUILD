load("//:defs.bzl", "dhall_json", "dhall_library", "dhall_yaml")

package(default_visibility = ["//visibility:public"])

dhall_library(
    name = "with_data",
    data = [":extra.txt"],
    entrypoint = "with_data.dhall",
    tags = ["block-network"],
)

dhall_yaml(
    name = "with_data_yaml",
    data = [":extra.txt"],
    entrypoint = "with_data.dhall",
    freeze = False,
    tags = ["block-network"],
)

dhall_json(
    name = "with_data_json",
    data = [":extra.txt"],
    entrypoint = "with_data.dhall",
    freeze = False,
    tags = ["block-network"],
)
