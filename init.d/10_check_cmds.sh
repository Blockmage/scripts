# shellcheck shell=bash

[[ -n "${BASH_VERSION:-}" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
HERE="$(cd "$(dirname "$SELF")" && pwd)" SELF="$HERE/$(basename "$SELF")"
[[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
  SOURCED="${SOURCED#:}:${SELF%:}"

check_cmds() {
  local result=0 cmds=("$@")
  for cmd in "${cmds[@]}"; do
    if [[ ! "$(command -v "$cmd")" ]]; then
      ((result += 1))
      echo "[ ERROR ]: Command '$cmd' is required and unavailable."
    fi
  done
  [[ "$result" -eq 0 ]] && return 0 || return 1
}

export SOURCED
