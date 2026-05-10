def _is_safe_name(name):
  if not name[0].isalpha():
    return False
  for sub in name.elems():
    if not sub.isalnum() and sub != "_":
      return False
  return True

def _stage_data(ctx, entrypoint):
  """Stage `data` files alongside a copy of `entrypoint` so dhall's `./foo`
  relative imports resolve to bazel-managed symlinks rather than to a
  shell-time `cp -f` target.

  Files are staged under <package>/<name>_dhall_data/ in bazel-out, so:

    * the staged paths live in bazel-out (never the source tree -- removes
      the source-tree-poisoning footgun under --spawn_strategy=local),
    * dhall opens the *staged* entrypoint, and `./foo` resolves to the
      sibling staged data file (sandbox-clean, no realpath dance),
    * two data labels with the same basename collide loudly at analysis
      time on declare_file rather than silently clobbering via `cp -f`.

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

def _dhall_library_impl(ctx):
  """A rule that processes dhall files and creates a tarfile of binary encodings"""
  entrypoint = ctx.attr.entrypoint.files.to_list()[0]
  if not _is_safe_name(ctx.attr.name):
    fail(attr="name", msg="Must use bash variable name safe values")

  output = ctx.actions.declare_file(ctx.label.name + "_tar")

  staged_entrypoint, staged_data = _stage_data(ctx, entrypoint)

  inputs = []
  inputs.append(staged_entrypoint)
  inputs.extend(staged_data)

  # Build command
  cmd = []
  cmd.append(ctx.attr._dhall_library.files_to_run.executable.path)
  if ctx.attr.verbose == True:
    cmd.append( "-v")

  # Add tar files to the command and to the inputs
  for dep in ctx.attr.deps:
    cmd.append( "-d " + dep.files.to_list()[0].path)
    inputs.append( dep.files.to_list()[0] )

  # add all sources to the inputs
  for file in ctx.files.srcs:
    inputs.append(file)

  cmd.append(ctx.attr._dhall.files_to_run.executable.path)
  cmd.append(output.path)
  cmd.append(staged_entrypoint.path)

  ctx.actions.run_shell(
    inputs = inputs,
    outputs = [ output ],
    progress_message = "Generating dhall files into '%s'" % output.path,
    tools = [ ctx.attr._dhall.files_to_run, ctx.attr._dhall_library.files_to_run ],
    command = " ".join(cmd),
    mnemonic = "DhallCompile"
  )

  return [ DefaultInfo(files = depset([ output ])) ]

dhall_library = rule(
    implementation = _dhall_library_impl,
    attrs = {
      "entrypoint": attr.label(mandatory = True, allow_single_file = True),
      "srcs": attr.label_list(allow_files = [".dhall"]),
      "deps": attr.label_list(),
      "data": attr.label_list(allow_files = True),
      "verbose": attr.bool( default = False ), 
      "_dhall": attr.label(
            default = Label("//cmds:dhall"),
            executable = True,
            cfg = "host"
      ),
      "_dhall_library": attr.label(
            default = Label("//rules:dhall-library"),
            executable = True,
            cfg = "host"
      ),
    }
)

def _dhall_library_docs_impl(ctx):
  output = ctx.actions.declare_file(ctx.label.name + "_tar")

  inputs = []
  for file in ctx.files.srcs:
    inputs.append(file)

  cmd = []
  cmd.append(ctx.attr._dhall_library_docs.files_to_run.executable.path)
  cmd.append(ctx.attr._dhall_docs.files_to_run.executable.path)
  cmd.append(ctx.files.entrypoint[0].dirname)
  cmd.append(output.path)

  ctx.actions.run_shell(
    inputs = inputs,
    outputs = [ output ],
    progress_message = "Creating dhall library docs into '%s'" % output.path,
    tools = [ ctx.attr._dhall_docs.files_to_run, ctx.attr._dhall_library_docs.files_to_run ],
    command = " ".join(cmd),
  )

  return [ DefaultInfo(files = depset([ output ])) ]


dhall_library_docs = rule(
    implementation = _dhall_library_docs_impl,
    attrs = {
      "entrypoint": attr.label(mandatory = True, allow_single_file = True),
      "srcs": attr.label_list(allow_files = True),
      "deps": attr.label_list(),
      "data": attr.label_list(allow_files = True),
      "verbose": attr.bool( default = False ), 
      "_dhall_docs": attr.label(
            default = Label("//cmds:dhall-docs"),
            executable = True,
            cfg = "host"
      ),
      "_dhall_library_docs": attr.label(
            default = Label("//rules:dhall-docs"),
            executable = True,
            cfg = "host"
      ),
    }
)
