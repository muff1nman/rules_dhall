# rules_dhall
This repo contains experimental rules for [bazel](https://bazel.build/) to generate files
using [Dhall](https://dhall-lang.org).

The rules use the method described by [@Gabriel439](https://github.com/Gabriel439) in [this answer](https://stackoverflow.com/questions/61139099/how-can-i-access-the-output-of-a-bazel-rule-from-another-rule-without-using-a-re)
 on stack overflow.

rules_dhall fetches binary releases of dhall from github - see section [command targets](#command-targets).

## Public API

The output-producing macros (`dhall_library`, `dhall_yaml`, `dhall_json`)
each accept a `freeze` keyword. When `freeze = True` (the default), a
`<name>_freeze` companion target is emitted alongside the main rule.
The companion is a `bazel run`-able executable that re-freezes the
entrypoint's imports using the same `entrypoint`, `srcs`, `deps`, `data`
and `verbose` attributes -- so the freeze target can never drift away
from what gets rendered.

Pass `freeze = False` when the entrypoint lives in an external repository
or when another macro for the same entrypoint already emits the freeze
companion (typical when you produce both a library and yaml/json from the
same `.dhall` file: keep `freeze = True` on the library, set `freeze = False`
on the yaml/json siblings).

The bare `dhall_freeze` rule is intentionally **not** exported from
`defs.bzl`. Its underlying rule still exists in `rules/dhall_freeze.bzl`
with kind `dhall_freeze`, so `bazel query 'kind("dhall_freeze", //...)'`
keeps working for tooling that wants to discover all freeze targets in a
workspace.

### dhall_library
Build a Dhall library tar from an entrypoint. The output is a tar archive
containing:
* the binary encoded, alpha normalized dhall expression (`.cache/dhall`)
* the dhall source file (`source.dhall`)
* a placeholder that includes the sha256 hash (`binary.dhall`)

Attribute  | Description |
---------- |  ---- |
name       | __string; required.__  Must be bash variable safe (alphanumeric with underscores).
entrypoint | __label; required.__  The dhall file containing the package's entrypoint expression. References from another dhall package _must_ include the sha256 hash (see `freeze`).
srcs       | __List of labels; optional.__ Source files referenced from `entrypoint`.
deps       | __List of labels; optional.__ `dhall_library` targets this rule depends on.
data       | __List of labels; optional.__ Outputs of these targets are copied next to `entrypoint` so dhall can reference them.
verbose    | __bool; optional.__  If True, output verbose logging.
freeze     | __bool; optional, default True.__ When True, also emit a `<name>_freeze` `bazel run` target that re-freezes the entrypoint's imports.

See example [abcd](examples/abcd).

### dhall_yaml / dhall_json
Render a Dhall entrypoint to YAML or JSON.

Attribute   | Description |
----------- | -----------|
name        | __string; required.__ |
entrypoint  | __label; required.__  See `dhall_library`. |
srcs        | __List of labels; optional.__ |
deps        | __List of labels; optional.__ `dhall_library` targets this rule depends on. |
data        | __List of labels; optional.__ |
out         | __string; optional.__ Defaults to the entrypoint's basename plus `.yaml` or `.json`.
verbose     | __bool; optional.__  If True, output verbose logging.
dhall_args  | __List of string; optional.__ Additional arguments to `dhall-to-yaml` / `dhall-to-json`.
freeze      | __bool; optional, default True.__ When True, also emit a `<name>_freeze` companion target. Set to False when another macro for the same entrypoint already produces the freeze target.

See example [abcd](examples/abcd).

### dhall_prelude / dhall_k8s

Convenience helpers that wire `dhall_library` against the
`@dhall-prelude` / `@dhall-kubernetes` external repositories, plus a
`<name>_docs` companion via `dhall_library_docs`. Both pass
`freeze = False` because the entrypoints live in external repos and
re-freezing wouldn't write back to anything user-editable.

```starlark
dhall_k8s(name = "k8s", version = "1.17")
dhall_prelude(name = "prelude")
```

## Command targets

To run dhall or dhall-to-yaml via bazel:
```shell script
bazel run //cmds:dhall -- --help
bazel run //cmds:dhall-to-yaml -- --help
bazel run //cmds:dhall-to-json -- --help
```

## Usage with dhall-kubernetes

It is possible to use these rules in combination with [dhall-kubernetes](https://github.com/dhall-lang/dhall-kubernetes). See example [k8s](examples/k8s).

## Note on freezing dependencies
rules_dhall relies on the semantic integrity checking feature of dhall.
For this to work, expressions referenced from another dhall package must
include the sha256 hash. Use the `<name>_freeze` companion targets (or
`tools/freeze.sh`-style tooling that walks
`bazel query 'kind("dhall_freeze", //...)'`) to refresh those hashes
when a referenced expression changes.

## Note on hashing
To find the hash for a given package/tar:
```shell script
$ bazel run //rules:dhall-hash -- <path to tarfile>
```

## Note on network
rules_dhall allows preventing dhall from accessing internet resources via the
`block-network` tag. This aides in ensuring dhall uses the bazel dependencies.
Note that this requires the experimental flag
`--experimental_allow_tags_propagation` which is set in the `.bazelrc` adjacent
to the workspace. See [bazel issue
8830](https://github.com/bazelbuild/bazel/issues/8830) for more detail on the
experimental flag and [bazels documentation on
tags](https://docs.bazel.build/versions/master/be/common-definitions.html#common-attributes)
for information about `block-network`.
