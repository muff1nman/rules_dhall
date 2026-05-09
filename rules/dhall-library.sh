#!/usr/bin/env bash
#
# Script that creates a tarfile of the encoded input plus all dependencies
#
set -euo pipefail

###############
## FUNCTIONS ##
###############
function unpack_tars() {
  # $TARS is formated as a space-separated list of names and paths like
  # k8s generators/k8s_tar prelude generators/prelude_tar
  for arg in "$@"
  do
    debug_log "Unpacking $arg into $XDG_CACHE_HOME"
    debug_log "$(tar -tvf "$arg")"
    tar -xf "$arg" --strip-components=2 -C "$XDG_CACHE_HOME/dhall" .cache
  done
}

function copy_resources() {
  for resource in "$@"; do
    local source_path target_path target_file
    source_path=$(cut -d':' -f 1 <<< "${resource}")
    target_path=$(cut -d':' -f 2 <<< "${resource}")

    # If the destination is a directory, the eventual file path is
    # <target_path>/<basename(source)>; check that for the self-copy guard
    # below.
    if [[ -d "$target_path" ]]; then
      target_file="${target_path%/}/$(basename "$source_path")"
    else
      target_file="$target_path"
    fi

    if [[ -e "$target_file" && "$source_path" -ef "$target_file" ]]; then
      # Sandboxes hand us source files as symlinks pointing back at their
      # original location. When `data` happens to live next to the
      # entrypoint, `cp -f` would refuse with "are the same file" because
      # GNU coreutils sees the inode collision after symlink resolution.
      # The file is already where dhall expects it, so the copy is a no-op.
      debug_log "Skipping self-copy: $source_path is already at $target_file"
      continue
    fi

    debug_log "Copying $source_path to $target_path"
    cp -f "$source_path" "$target_path"
  done
}

function dump_cache() {
  if [ "$DEBUG" -eq 1 ]
  then
    echo "DUMPING CACHE $1 START" >&2
    ls -l "$2" >&2
    echo "DUMPING CACHE $1 STOP" >&2
  fi
}

function debug_log() {
 if [ "$DEBUG" -eq 1 ]
 then
    echo "$(basename "$0") DEBUG: $1" >&2
  fi
}

##########
## MAIN ##
##########
DEBUG=0

TARS=""
RESOURCES=""
while getopts "vd:r:" arg; do
  # We handle the rest of the arguments below
  # shellcheck disable=SC2220
  case "$arg" in
    v)
      DEBUG=1
      ;;
    d)
      TARS="$TARS $OPTARG"
      ;;
    r)
      RESOURCES="$RESOURCES $OPTARG"
      ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -ne 3 ]; then
  echo "Usage: $0 [-v] [-d <dep-tar-file>] [-r <source_path>:<target_path>] <dhall-binary> <output-tarfile> <dhall-input-file> "
  exit 2
fi

DHALL_BIN=$1
TARFILE=$2
# Pass the entrypoint to dhall as-given (relative to the action's PWD,
# which is the execroot). Resolving symlinks here would point dhall at
# the file's canonical location *outside* the sandbox, where the
# `copy_resources`-staged data files don't exist -- breaking entrypoints
# that import sibling files via `./foo` or `./foo as Text`. Keeping the
# path relative lets dhall's own import resolution stay inside the
# sandbox-mounted execroot.
DHALL_FILE=$3

export XDG_CACHE_HOME="$PWD/.cache"

debug_log "Working directory: ${PWD}"
debug_log "Cache: ${XDG_CACHE_HOME}"
debug_log "Dhall binary: ${DHALL_BIN}"
debug_log "Package deps: ${TARS}"
debug_log "Resources: ${RESOURCES}"

mkdir -p "$XDG_CACHE_HOME/dhall"

# We want the variable to expand into multiple args
# shellcheck disable=SC2086
unpack_tars $TARS

# We want the variable to expand into multiple args
# shellcheck disable=SC2086
copy_resources $RESOURCES

dump_cache "BEFORE_GEN" "$XDG_CACHE_HOME/dhall"

debug_log "Generating source.dhall"
if ! ${DHALL_BIN} --alpha --file "${DHALL_FILE}" > source.dhall
then
  exit $?
fi

SHA_HASH=$(${DHALL_BIN} hash --file source.dhall)

HASH_FILE="${SHA_HASH/sha256:/1220}"

debug_log "Hash is $HASH_FILE"
if ! ${DHALL_BIN} encode --file source.dhall > "$XDG_CACHE_HOME/dhall/$HASH_FILE"
then
  exit $?
fi

dump_cache "AFTER_GEN" "$XDG_CACHE_HOME/dhall"

debug_log "Creating tarfile $TARFILE"
tar -cf "$TARFILE" -C "$PWD" ".cache/dhall/$HASH_FILE"
tar -rf "$TARFILE" source.dhall
echo "missing $HASH_FILE" > binary.dhall
tar -rf "$TARFILE" binary.dhall

debug_log "Removing source.dhall"
rm source.dhall
