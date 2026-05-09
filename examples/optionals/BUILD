load("//:defs.bzl", "dhall_json", "dhall_library", "dhall_yaml")

package(default_visibility = ["//visibility:public"])

# `dhall_library` emits the freeze companion; `dhall_yaml`/`dhall_json` for the
# same entrypoint set `freeze = False` so we don't get redundant `_freeze`
# targets pointing at the same source.
dhall_library(
    name = "optionals",
    entrypoint = "optionals.dhall",
    tags = ["block-network"],
)

dhall_yaml(
    name = "optionals_yaml",
    entrypoint = "optionals.dhall",
    freeze = False,
    tags = ["block-network"],
)

dhall_json(
    name = "optionals_json",
    entrypoint = "optionals.dhall",
    freeze = False,
    tags = ["block-network"],
)

# This one suppresses empty items.
dhall_yaml(
    name = "optionals_with_args",
    out = "optionals_with_args.yaml",
    dhall_args = ["--omit-empty"],
    entrypoint = "optionals.dhall",
    freeze = False,
    tags = ["block-network"],
)

# This one fixes the types to get the same outcome.
dhall_library(
    name = "optionals2",
    entrypoint = "optionals2.dhall",
    tags = ["block-network"],
)

dhall_yaml(
    name = "optionals2_yaml",
    entrypoint = "optionals2.dhall",
    freeze = False,
    tags = ["block-network"],
)

dhall_json(
    name = "optionals2_json",
    entrypoint = "optionals2.dhall",
    freeze = False,
    tags = ["block-network"],
)
