# shellcheck shell=bash

[[ -n "${BASH_VERSION:-}" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
HERE="$(cd "$(dirname "$SELF")" && pwd)" SELF="$HERE/$(basename "$SELF")"
[[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
  SOURCED="${SOURCED#:}:${SELF%:}"

rename_ext() {
  # If the `rename` command is available, this is much simpler, e.g.:
  #   rename 's/\.jpg$/.jpeg/i' *.jpg
  local from_ext to_ext where
  where="$(pwd)"
  if [[ "$#" -eq 3 && -d "$1" ]]; then where="$1" && shift; fi
  if [[ "$#" -eq 2 ]]; then
    from_ext="$1" to_ext="$2"
    find "$where" -maxdepth 1 -iname "*.${from_ext}" -type f -exec \
      bash -c 'mv "$1" "${1%.'"$from_ext"'}.'"$to_ext"'"' _ {} \;
  else
      {
      echo "[ ERROR ]: Wrong number of args."
      echo ""
      echo "Usage:"
      echo "  rename_ext 'FROM_EXT' 'TO_EXT'"
      echo "  rename_ext '/path/to/dir' 'FROM_EXT' 'TO_EXT'"
      echo ""
      echo "Examples:"
      echo "  Rename all '*.jpeg' files in the working directory to '*.jpg':"
      echo "    rename_ext 'jpeg' 'jpg'"
      echo "  Rename all '*.md' files in a different directory to '*.mdx':"
      echo "    rename_ext '/path/to/dir' 'md' 'mdx'"
    } >&2
    return 1
  fi
}

export SOURCED
