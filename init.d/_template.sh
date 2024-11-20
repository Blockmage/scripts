# shellcheck shell=bash

[[ -n "${BASH_VERSION:-}" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
[[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
  SOURCED="${SOURCED#:}:${SELF%:}"

# <-- Do stuff here -->

export SOURCED
