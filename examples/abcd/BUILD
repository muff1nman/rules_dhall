load("//:defs.bzl", "dhall_json", "dhall_library", "dhall_yaml")

package(default_visibility = ["//visibility:public"])

dhall_library(
    name = "a",
    entrypoint = "a.dhall",
    tags = ["block-network"],
    deps = [
        ":b",
        ":c",
    ],
)

dhall_yaml(
    name = "a_yaml",
    entrypoint = "a.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":b",
        ":c",
    ],
)

dhall_json(
    name = "a_json",
    entrypoint = "a.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":b",
        ":c",
    ],
)

dhall_library(
    name = "b",
    entrypoint = "b.dhall",
    tags = ["block-network"],
    deps = [
        ":d",
    ],
)

dhall_library(
    name = "c",
    entrypoint = "c.dhall",
    tags = ["block-network"],
)

dhall_library(
    name = "d",
    entrypoint = "d.dhall",
    tags = ["block-network"],
)

# This one adds an additional yaml target using an explicit output filename of ouch.yaml.
dhall_yaml(
    name = "ouch_yaml",
    out = "ouch.yaml",
    entrypoint = "a.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":b",
        ":c",
    ],
)

## This one does not use any intermediate targets
# TODO:broken
#dhall_yaml(
#    name = "a_no_intermediates_yaml",
#    entrypoint = "a-direct.dhall",
#    out = "a_no_intermediates.yaml",
#    srcs = [ "b.dhall", "c.dhall", "d.dhall" ]
#)
