
"""A rule that processes dhall files and creates an output"""

def _stage_data(ctx, entrypoint):
  """Stage `data` files alongside a copy of `entrypoint` so dhall's `./foo`
  relative imports resolve to bazel-managed symlinks rather than to a
  shell-time `cp -f` target. See dhall_library.bzl for the full rationale.

  Returns (staged_entrypoint, [staged_data...]) when staging happens, or
  (entrypoint, []) when there is no data and the unstaged entrypoint
  works just as well.
  """
  if not ctx.attr.data:
    return entrypoint, []

  stage_prefix = ctx.label.name + "_dhall_data/"
  staged_entrypoint = ctx.actions.declare_file(stage_prefix + entrypoint.basename)
  ctx.actions.symlink(output = staged_entrypoint, target_file = entrypoint)

  staged = []
  for data in ctx.attr.data:
    src = data.files.to_list()[0]
    out = ctx.actions.declare_file(stage_prefix + src.basename)
    ctx.actions.symlink(output = out, target_file = src)
    staged.append(out)

  return staged_entrypoint, staged

def _dhall_output_impl(ctx):
  entrypoint = ctx.attr.entrypoint.files.to_list()[0]

  output_file = entrypoint.basename[0:-6] + "." + ctx.attr._format

  if ctx.attr.out != "":
    output_file = ctx.attr.out

  output = ctx.actions.declare_file(output_file)

  staged_entrypoint, staged_data = _stage_data(ctx, entrypoint)

  inputs = []
  inputs.append(staged_entrypoint)
  inputs.extend(staged_data)

  # Build command
  cmd = []
  cmd.append( ctx.attr._dhall_output.files_to_run.executable.path )
  if ctx.attr.verbose == True:
    cmd.append( "-v")

  # Add tar files to the command and to the inputs
  for dep in ctx.attr.deps:
    cmd.append( "-d " + dep.files.to_list()[0].path)
    inputs.append( dep.files.to_list()[0] )

  # add all sources to the inputs
  for src in ctx.attr.srcs:
    file = src.files.to_list()[0]
    inputs.append(file)

  cmd.append( ctx.attr._dhall_command.files_to_run.executable.path )
  cmd.append( output.path )
  cmd.append( staged_entrypoint.path )

  ctx.actions.run_shell(
    inputs = inputs,
    outputs = [ output ],
    progress_message = "Generating output into '%s'" % output.path,
    tools = [ ctx.attr._dhall_command.files_to_run, ctx.attr._dhall_output.files_to_run ],
    command = " ".join(cmd),
    mnemonic = "DhallCompile",
    env = {
        "_DHALL_ARGS": " ".join(ctx.attr.dhall_args)
    }
  )
  return [ DefaultInfo(files = depset([ output ])) ]

dhall_yaml = rule(
    implementation = _dhall_output_impl,
    attrs = {
      "entrypoint": attr.label(mandatory = True, allow_single_file = True),
      "srcs": attr.label_list(allow_files = [".dhall"]),
      "deps": attr.label_list(),
      "data": attr.label_list(allow_files = True),
      "out": attr.string(mandatory = False),
      "verbose": attr.bool( default = False ), 
      "dhall_args": attr.string_list(mandatory = False),
      "_format": attr.string(default = "yaml"),
      "_dhall_command": attr.label(
            default = Label("//cmds:dhall-to-yaml"),
            executable = True,
            cfg = "host"
      ),
      "_dhall_output": attr.label(
            default = Label("//rules:dhall-output"),
            executable = True,
            cfg = "host"
      ),
    }
)

dhall_json = rule(
    implementation = _dhall_output_impl,
    attrs = {
      "entrypoint": attr.label(mandatory = True, allow_single_file = True),
      "srcs": attr.label_list(allow_files = [".dhall"]),
      "deps": attr.label_list(),
      "data": attr.label_list(allow_files = True),
      "out": attr.string(mandatory = False),
      "verbose": attr.bool( default = False ), 
      "dhall_args": attr.string_list(mandatory = False),
      "_format": attr.string(default = "json"),
      "_dhall_command": attr.label(
            default = Label("//cmds:dhall-to-json"),
            executable = True,
            cfg = "host"
      ),
      "_dhall_output": attr.label(
            default = Label("//rules:dhall-output"),
            executable = True,
            cfg = "host"
      ),
    }
)

