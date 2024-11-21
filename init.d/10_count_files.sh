# shellcheck shell=bash

[[ -n "${BASH_VERSION:-}" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
HERE="$(cd "$(dirname "$SELF")" && pwd)" SELF="$HERE/$(basename "$SELF")"
[[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
  SOURCED="${SOURCED#:}:${SELF%:}"

count_files() {
  local what where
  where="$(pwd)" what="$1"
  [[ "$#" -eq 2 && -d "$1" ]] && where="$1" what="$2"
  find "$where" -maxdepth 1 -iname "$what" -type f | wc -l 2>/dev/null
}

export SOURCED
