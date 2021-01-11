package(default_visibility = ["//visibility:public"])

load("//:defs.bzl", "dhall_macro", "dhall_prelude")

dhall_prelude(name = "prelude")

dhall_macro(
    name = "false",
    entrypoint = "false.dhall",
    deps = [
        ":prelude",
    ],
    tags = ["block-network"],
)
