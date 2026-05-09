load("//:defs.bzl", "dhall_json", "dhall_k8s", "dhall_library", "dhall_prelude", "dhall_yaml")

package(default_visibility = ["//visibility:public"])

dhall_k8s(
    name = "k8s",
    version = "1.16",
)

dhall_prelude(name = "prelude")

dhall_library(
    name = "ingress",
    entrypoint = "ingress.dhall",
    tags = ["block-network"],
    deps = [
        ":k8s",
        ":prelude",
    ],
)

dhall_yaml(
    name = "ingress_yaml",
    entrypoint = "ingress.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":k8s",
        ":prelude",
    ],
)

dhall_json(
    name = "ingress_json",
    entrypoint = "ingress.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":k8s",
        ":prelude",
    ],
)
