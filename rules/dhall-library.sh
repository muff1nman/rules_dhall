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
while getopts "vd:" arg; do
  # We handle the rest of the arguments below
  # shellcheck disable=SC2220
  case "$arg" in
    v)
      DEBUG=1
      ;;
    d)
      TARS="$TARS $OPTARG"
      ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -ne 3 ]; then
  echo "Usage: $0 [-v] [-d <dep-tar-file>] <dhall-binary> <output-tarfile> <dhall-input-file>"
  exit 2
fi

DHALL_BIN=$1
TARFILE=$2
# Pass the entrypoint to dhall as-given (relative to the action's PWD,
# which is the execroot). Resolving symlinks here would point dhall at
# the file's canonical location *outside* the sandbox, where the
# rule-side staged data symlinks don't exist -- breaking entrypoints
# that import sibling files via `./foo` or `./foo as Text`. Keeping
# the path relative lets dhall's own import resolution stay inside the
# sandbox-mounted execroot.
DHALL_FILE=$3

# Per-invocation scratch dir. Holds the dhall-cache, source.dhall and
# binary.dhall scratch files. Putting these under $PWD (the action's
# execroot) used to race when several actions ran in the same execroot
# under --spawn_strategy=local: source.dhall is non-unique and parallel
# invocations would clobber each other ('source.dhall: openFile: does
# not exist' / 'tar: source.dhall: File shrank'). mktemp gives each
# invocation its own writable dir; the trap cleans it up regardless of
# how the script exits.
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
export XDG_CACHE_HOME="$WORK_DIR/.cache"

debug_log "Working directory: ${PWD}"
debug_log "Scratch dir: ${WORK_DIR}"
debug_log "Cache: ${XDG_CACHE_HOME}"
debug_log "Dhall binary: ${DHALL_BIN}"
debug_log "Package deps: ${TARS}"

mkdir -p "$XDG_CACHE_HOME/dhall"

# We want the variable to expand into multiple args
# shellcheck disable=SC2086
unpack_tars $TARS

dump_cache "BEFORE_GEN" "$XDG_CACHE_HOME/dhall"

debug_log "Generating source.dhall"
if ! ${DHALL_BIN} --alpha --file "${DHALL_FILE}" > "$WORK_DIR/source.dhall"
then
  exit $?
fi

SHA_HASH=$(${DHALL_BIN} hash --file "$WORK_DIR/source.dhall")

HASH_FILE="${SHA_HASH/sha256:/1220}"

debug_log "Hash is $HASH_FILE"
if ! ${DHALL_BIN} encode --file "$WORK_DIR/source.dhall" > "$XDG_CACHE_HOME/dhall/$HASH_FILE"
then
  exit $?
fi

dump_cache "AFTER_GEN" "$XDG_CACHE_HOME/dhall"

debug_log "Creating tarfile $TARFILE"
echo "missing $HASH_FILE" > "$WORK_DIR/binary.dhall"
tar -cf "$TARFILE" -C "$WORK_DIR" ".cache/dhall/$HASH_FILE" source.dhall binary.dhall
