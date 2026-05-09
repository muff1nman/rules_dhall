load("//:defs.bzl", "dhall_json", "dhall_k8s", "dhall_library", "dhall_prelude", "dhall_yaml")

package(default_visibility = ["//visibility:public"])

dhall_k8s(
    name = "k8s",
    version = "1.17",
)

dhall_prelude(name = "prelude")

dhall_library(
    name = "server",
    entrypoint = "server.dhall",
    tags = ["block-network"],
)

dhall_yaml(
    name = "server_yaml",
    entrypoint = "server.dhall",
    freeze = False,
    tags = ["block-network"],
)

dhall_json(
    name = "server_json",
    entrypoint = "server.dhall",
    freeze = False,
    tags = ["block-network"],
)

# This demonstrates that it is possible to reference the output of dhall_yaml.
dhall_library(
    name = "configmap",
    data = [":server_yaml"],
    entrypoint = "configmap.dhall",
    tags = ["block-network"],
    deps = [
        ":k8s",
        ":prelude",
    ],
)

dhall_yaml(
    name = "configmap_yaml",
    data = [":server_yaml"],
    entrypoint = "configmap.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":k8s",
        ":prelude",
    ],
)

dhall_json(
    name = "configmap_json",
    data = [":server_yaml"],
    entrypoint = "configmap.dhall",
    freeze = False,
    tags = ["block-network"],
    deps = [
        ":k8s",
        ":prelude",
    ],
)
