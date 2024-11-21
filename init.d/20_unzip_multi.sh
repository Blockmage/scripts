# shellcheck shell=bash

# Description:
#
#	  This file provides a function, 'unzip_multi', which is useful for unzipping
#	  multiple archives at once, while merging any resulting output directories to
#	  form a single structure.
#
#   The function will dynamically infer from input of 0-2 arguments:
#	    - A prefix by which to filter found '*.zip' archives, selecting those
#       which should be extracted accordingly (e.g., 'myfile' to match
#       'myfile_abc1.zip', 'myfile_def2.zip', etc. in the working directory).
#     - A target output directory path to which the files should be extracted.
#
#   When called without arguments, the function will extract all ZIP files in
#   in the current working directory, into a new subdirectory named 'unzipped_'
#   + the current Unix timestamp.
#
#   If available, the function will utilize GNU `parallel` or `xargs` to speed
#   up the process by extracting multiple ZIP files simultaneously.
#
#   The output directory can be overridden by setting 'UNZIP_OUTPUT_DIR', and
#   the file prefix can be overridden by setting 'UNZIP_FILE_PREFIX'.
#
# Usage:
#
#   unzip_multi
#   # or
#   mkdir ./output_dir && unzip_multi "prefix" "output_dir"
#   # or
#   unzip_multi "prefix"
#   # or
#	  unzip_mutli "/path/to/output_dir"
#
# Dependencies:
#
#   Required:
#     - unzip
#     - count_files (from ./10_count_files.sh)
#
#   Optional:
#     - parallel
#     - xargs
#     - nproc

[[ -n "${BASH_VERSION:-}" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
HERE="$(cd "$(dirname "$SELF")" && pwd)" SELF="$HERE/$(basename "$SELF")"
[[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
  SOURCED="${SOURCED#:}:${SELF%:}"

unzip_multi() {
  local output_dir targ_dir zf_prefix zf
  if [[ "$(count_files "*.zip")" -ge 1 ]]; then
    zf_prefix="" output_dir="$(pwd)/unzipped_$(date +%s)" targ_dir="$(pwd)"

    if [[ "$#" -eq 1 ]]; then
      if [[ -d "$1" || "$1" == *"/"* ]]; then
        output_dir="$1"
      else zf_prefix="$1"; fi

    elif [[ "$#" -eq 2 ]]; then
      if [[ -d "$1" || "$1" == *"/"* ]]; then
        output_dir="$1" zf_prefix="$2"
      elif [[ -d "$2" || "$2" == *"/"* ]]; then
        output_dir="$2" zf_prefix="$1"
      fi
    fi

    [[ -n "${UNZIP_OUTPUT_DIR:-}" ]] && output_dir="$UNZIP_OUTPUT_DIR" || :
    [[ -n "${UNZIP_FILE_PREFIX:-}" ]] && zf_prefix="$UNZIP_FILE_PREFIX" || :

    mkdir -p "$output_dir"

    if [[ "$(command -v parallel)" ]]; then
      find "$targ_dir" -maxdepth 1 -iname "${zf_prefix}*.zip" -type f -print0 |
        parallel -0 -j+0 \
          "echo 'Extracting {} into $output_dir ...' && \
          unzip -q -o -DD {} -d '$output_dir'"

    elif [[ "$(command -v xargs)" ]]; then
      local numpr
      if [[ "$(command -v nproc)" ]]; then
        numpr="$(nproc)"
      elif [[ "${OSTYPE:-}" == *"darwin"* ]]; then
        numpr="$(sysctl -n hw.logicalcpu)"
      else numpr=4; fi

      find "$targ_dir" -maxdepth 1 -iname "${zf_prefix}*.zip" -type f -print0 |
        xargs -0 -P "$numpr" -I {} \
          sh -c "echo 'Extracting {} into $output_dir ...' && \
          unzip -q -o -DD {} -d '$output_dir'"

    else
      for zf in "$zf_prefix"*.zip; do
        echo "Extracting $zf into $output_dir ..."
        unzip -q -o -DD "$zf" -d "$output_dir"
      done
    fi
  else
    echo "[ ERROR ]: No ZIP files found in working directory."
    return 1
  fi
}

export SOURCED
