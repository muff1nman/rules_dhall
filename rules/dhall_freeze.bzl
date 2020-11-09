load("@bazel_skylib//lib:shell.bzl", "shell")

"""A rule that outputs frozen dhall"""
def _dhall_freeze_impl(ctx):
  entrypoint = ctx.attr.entrypoint.files.to_list()[0]

  substitutions = {
		  "@@ENTRYPOINT@@": entrypoint.path,
		  "@@DHALL_BIN@@": ctx.attr._dhall[DefaultInfo].files_to_run.executable.short_path,
		  }

  inputs = []
  inputs.append(entrypoint)

  deps = []
  # Add tar files to the command and to the inputs
  for dep in ctx.attr.deps:
    deps.append(dep.label.name)
    deps.append(dep.files.to_list()[0].short_path)
    inputs.append(dep.files.to_list()[0])

  substitutions["@@DEPS@@"] = shell.array_literal(deps)

  for data in ctx.attr.data:
    inputs.append( data.files.to_list()[0] )

  # add all sources to the inputs
  for file in ctx.files.srcs:
    inputs.append(file)

  ctx.actions.expand_template(
		  template = ctx.file._dhall_freeze,
		  output = ctx.outputs.executable,
		  substitutions = substitutions,
		  is_executable = True,
		  )

  freeze_runfiles = ctx.runfiles(files = inputs)
  freeze_runfiles = freeze_runfiles.merge(ctx.attr._dhall[DefaultInfo].default_runfiles)

  return [ DefaultInfo(runfiles = freeze_runfiles) ]

dhall_freeze = rule(
    implementation = _dhall_freeze_impl,
    executable = True,
    attrs = {
      "entrypoint": attr.label(mandatory = True, allow_single_file = True),
      "srcs": attr.label_list(allow_files = [".dhall"]),
      "deps": attr.label_list(),
      "data": attr.label_list(),
      "verbose": attr.bool( default = False ), 
      "_dhall": attr.label(
            default = Label("//cmds:dhall"),
            executable = True,
            cfg = "host"
      ),
      "_dhall_freeze": attr.label(
            default = Label("//rules:dhall-freeze.sh"),
            allow_single_file = True
      ),
    }
)

