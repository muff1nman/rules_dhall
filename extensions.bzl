"""Bzlmod module extension that fetches the upstream dhall binaries
plus the dhall-prelude and dhall-kubernetes source archives.

Mirrors the WORKSPACE-style helpers in `deps.bzl`; both code paths can
coexist while consumers migrate from WORKSPACE to MODULE.bazel.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//:deps.bzl", "load_dhall_dependencies", "load_dhall_k8s_dependencies")

def _dhall_deps_impl(_module_ctx):
    load_dhall_dependencies()
    load_dhall_k8s_dependencies()

dhall_deps = module_extension(
    implementation = _dhall_deps_impl,
)
