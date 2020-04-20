package(default_visibility = ["//visibility:public"])

load("//:defs.bzl", "dhall_library", "dhall_output")

dhall_library(
    name = "a_dhall_library",
    entrypoint = "a.dhall",
    deps = [
        ":b_dhall_library",
        ":c_dhall_library",
    ],
)

dhall_library(
    name = "b_dhall_library",
    entrypoint = "b.dhall",
    deps = [
        ":d_dhall_library",
    ],
)

dhall_library(
    name = "c_dhall_library",
    entrypoint = "c.dhall",
)

dhall_library(
    name = "d_dhall_library",
    entrypoint = "d.dhall",
)

# This one uses an implicit output filename of a.yaml
dhall_output(
    name = "a_yaml",
    src = "a.dhall",
    deps = [
        ":b_dhall_library",
        ":c_dhall_library",
    ],
)

# This one uses an explicit output filename of ouch.yaml
dhall_output(
    name = "ouch_yaml",
    src = "a.dhall",
    out = "ouch.yaml",
    deps = [
        ":b_dhall_library",
        ":c_dhall_library",
    ],
)