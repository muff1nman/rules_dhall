"""Public macros for managing dhall builds.

The output-producing rules (`dhall_library`, `dhall_yaml`, `dhall_json`)
each accept a `freeze` keyword that controls whether a companion
`<name>_freeze` target is emitted alongside them. The companion target is
a `bazel run`-able executable that re-freezes the entrypoint's imports
(via the underlying `dhall_freeze` rule) using the same `entrypoint`,
`srcs`, `deps`, `data` and `verbose` attributes.

`freeze` defaults to `True`. Pass `freeze = False` to suppress the
companion -- typically when the entrypoint is sourced from an external
repository (see `dhall_prelude`, `dhall_k8s`) and re-freezing wouldn't
write back to anything user-editable.

The bare `dhall_freeze` rule is intentionally not re-exported: every
realistic use shares its `entrypoint`/`srcs`/`deps` with an output rule,
and forcing both rules to be declared by hand was the source of silent
drift between what gets rendered and what gets re-frozen.
"""

load("//rules:dhall_freeze.bzl", _dhall_freeze = "dhall_freeze")
load(
    "//rules:dhall_library.bzl",
    _dhall_library = "dhall_library",
    _dhall_library_docs = "dhall_library_docs",
)
load(
    "//rules:dhall_output.bzl",
    _dhall_json = "dhall_json",
    _dhall_yaml = "dhall_yaml",
)

# `dhall_library_docs` has no freeze companion concept (it produces docs,
# not a Dhall expression to re-freeze), so it stays a bare re-export.
dhall_library_docs = _dhall_library_docs

# Output-rule kwargs that `dhall_freeze` does not accept and must be
# stripped before emitting the freeze companion.
_FREEZE_INCOMPATIBLE_KWARGS = ("dhall_args", "out")

def _emit_freeze(name, kwargs):
    freeze_kwargs = {
        k: v
        for k, v in kwargs.items()
        if k not in _FREEZE_INCOMPATIBLE_KWARGS
    }
    _dhall_freeze(name = name + "_freeze", **freeze_kwargs)

def dhall_library(name, freeze = True, **kwargs):
    """Build a Dhall library tar from an entrypoint.

    Args:
      name: target name. The freeze companion is `<name>_freeze`.
      freeze: when True (default), also emit a `<name>_freeze` `bazel run`
        target that re-freezes the entrypoint's imports.
      **kwargs: forwarded to the underlying `dhall_library` rule (and,
        when `freeze = True`, to `dhall_freeze`, with `dhall_args` and
        `out` filtered out as those aren't accepted by `dhall_freeze`).
    """
    _dhall_library(name = name, **kwargs)
    if freeze:
        _emit_freeze(name, kwargs)

def dhall_yaml(name, freeze = True, **kwargs):
    """Render a Dhall entrypoint to YAML.

    Args:
      name: target name. The freeze companion is `<name>_freeze`.
      freeze: when True (default), also emit a `<name>_freeze` `bazel run`
        target that re-freezes the entrypoint's imports.
      **kwargs: forwarded to the underlying `dhall_yaml` rule (and, when
        `freeze = True`, to `dhall_freeze`, with `dhall_args` and `out`
        filtered out).
    """
    _dhall_yaml(name = name, **kwargs)
    if freeze:
        _emit_freeze(name, kwargs)

def dhall_json(name, freeze = True, **kwargs):
    """Render a Dhall entrypoint to JSON.

    Args:
      name: target name. The freeze companion is `<name>_freeze`.
      freeze: when True (default), also emit a `<name>_freeze` `bazel run`
        target that re-freezes the entrypoint's imports.
      **kwargs: forwarded to the underlying `dhall_json` rule (and, when
        `freeze = True`, to `dhall_freeze`, with `dhall_args` and `out`
        filtered out).
    """
    _dhall_json(name = name, **kwargs)
    if freeze:
        _emit_freeze(name, kwargs)

def dhall_prelude(name, visibility = None, **kwargs):
    """Create a prelude library wired to the @dhall-prelude repo.

    No freeze companion is emitted: the entrypoint lives in an external
    http_archive and re-freezing wouldn't write back to anything in the
    consumer's tree.
    """
    dhall_library(
        name = name,
        entrypoint = "@dhall-prelude//:Prelude/package.dhall",
        srcs = ["@dhall-prelude//:dhall-prelude"],
        visibility = visibility,
        tags = ["block-network"],
        freeze = False,
        **kwargs
    )
    dhall_library_docs(
        name = "%s_docs" % name,
        entrypoint = "@dhall-prelude//:Prelude/package.dhall",
        srcs = ["@dhall-prelude//:dhall-prelude"],
        visibility = visibility,
        tags = ["block-network"],
        **kwargs
    )

def dhall_k8s(name, version, visibility = None, **kwargs):
    """Create a Kubernetes package library for a given dhall-kubernetes version.

    No freeze companion is emitted: the entrypoint lives in an external
    http_archive and re-freezing wouldn't write back to anything in the
    consumer's tree.
    """
    dhall_library(
        name = name,
        entrypoint = "@dhall-kubernetes//:%s/package.dhall" % version,
        srcs = ["@dhall-kubernetes//:k8s-dhall-%s" % version],
        visibility = visibility,
        tags = ["block-network"],
        freeze = False,
        **kwargs
    )
    dhall_library_docs(
        name = "%s_docs" % name,
        entrypoint = "@dhall-kubernetes//:%s/package.dhall" % version,
        srcs = ["@dhall-kubernetes//:k8s-dhall-%s" % version],
        visibility = visibility,
        tags = ["block-network"],
        **kwargs
    )
