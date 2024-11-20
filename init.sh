# shellcheck shell=bash

# ---------------------------------- Overview ----------------------------------
#
#   This script can be used as a flexible way to initialize and source
#   additional files. It expects to find files located in a directory named
#   'init.d' in the same location as this file.
#
#   This script should be sourced (e.g., `source init.sh` or `\. init.sh`) and
#   will exit early if called directly. It will additionally exit early if the
#   current shell context is not Zsh or Bash (v4+). Files located in the
#   'init.d' directory are expected to be valid for either shell.
#
#   This script will search for '*.env' files (up to a max depth of 2
#   directories) and source them prior to sourcing any '*.sh' files. This means
#   that files which may exist in 'init.d' will have any required configuration
#   values set prior to being sourced, assuming that these values are set in a
#   '*.env' file somewhere within the project directory.
#
#   The order that the '*.env' files are sourced follows the same logic used to
#   sort and source files in 'init.d', meaning both can utilize a naming scheme
#   like '00_file1.env', '10_file2.sh', etc. to be sourced in the correct order.
#
#   Lastly, all found '*.env' files will have permissions set to 600 and
#   ownership set the the calling user (the user sourcing this file). This
#   behavior can be disabled individually (for both ownership and permissions)
#   by setting variables 'DISABLE_INIT_CHMOD=1' and/or 'DISABLE_INIT_CHOWN=1'.
#   Environment files are sourced before they are potentially modified in this
#   way, so any '*.env' file could feasibly contain either variable to affect
#   this logic.
#
# ------------------------------ Quick Reference -------------------------------
#
#   Functions Defined in This File:
#     debug_sourced()     - Debug helper for tracking sourced files.
#     debug_log()         - Log debug messages for file operations.
#     chown_file()        - Change file ownership to 'CHOWN_AS'.
#     chmod_file()        - Change file permissions to 'CHMOD_MODE'.
#     chownmod()          - Apply both ownership and permission changes.
#     source_files()      - Source multiple files with debug logging.
#
#   Variables Defined in This File:
#     SHELLCTX            - Current shell context ('bash' or 'zsh').
#     WAS_SOURCED         - Flag indicating if script was sourced (0/1).
#     SELF                - Full path to current script.
#     HERE                - Directory containing current script.
#     PROJECT_ROOT        - Project root directory (defaults to $HERE).
#     SOURCED             - Colon-separated list of sourced files.
#     DOTENV_SOURCES      - Array of discovered .env files.
#     INIT_D_SOURCES      - Array of discovered init.d/*.sh files.
#
#   Environment Variables Used:
#     DEBUG               - Enable debug logging when set to 1.
#     DISABLE_INIT_CHOWN  - Disable ownership changes when set to 1.
#     DISABLE_INIT_CHMOD  - Disable permission changes when set to 1.
#     PROJECT_ROOT        - Can be preset to override default.
#     INIT_D              - Override to specify a directory to use as 'init.d'.
#     CREATE_INIT_D       - Enable creation of 'INIT_D' directory when set to 1.
#     CHOWN_AS            - Value in form of 'UID:GID' to use for chown.
#     CHMOD_MODE          - Octal mode to use for chmod (preserves -x for dirs).
#
# ---------------------------- Updates / Changelog -----------------------------
#
#   - 2024-11-19T09:57:04+00:00 : Version 0.1.0.
#
# ---------------------------------- License -----------------------------------
#
#   Copyright 2024 Alchemyst0x, Blockmage Ltd, and Contributors.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# ------------------------------------------------------------------------------

# ------------------------ Script Initialization Logic -------------------------

if [[ -n "${BASH_VERSION:-}" ]]; then
  (return 0 2>/dev/null) && WAS_SOURCED=1 || WAS_SOURCED=0
  [[ -z "${SHELLCTX:-}" ]] && readonly SHELLCTX="bash" || :
  # In downstream files, 'SELF' can be defined more concisely with, e.g.:
  # [[ "$SHELLCTX" == "bash" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
  SELF="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  [[ "${ZSH_EVAL_CONTEXT:-}" =~ :file$ ]] && WAS_SOURCED=1 || WAS_SOURCED=0
  [[ -z "${SHELLCTX:-}" ]] && readonly SHELLCTX="zsh" || :
  SELF="$0"
else
  echo "[ EXIT ]: Unsupported shell!" >&2
  exit 1
fi

if [[ "$WAS_SOURCED" == 0 ]]; then
  echo "[ EXIT ]: Source me please!" >&2
  exit 1
fi

if [[ "$SHELLCTX" == "bash" ]] && ((BASH_VERSINFO[0] < 4)); then
  echo "[ EXIT ]: Either Zsh or Bash (version 4 or later) is required." >&2
  return 1
fi

HERE="$(cd "$(dirname "$SELF")" && pwd)"
SELF="$HERE/$(basename "$SELF")"

# shellcheck disable=SC1091
[[ -s "$HERE/.env" ]] && \. "$HERE/.env" || :
PROJECT_ROOT="${PROJECT_ROOT:-"$HERE"}"
INIT_D="${INIT_D:-"$HERE/init.d"}"
export SHELLCTX PROJECT_ROOT

# shellcheck disable=SC2120
debug_sourced() {
  local file msg src env
  if [[ "${DEBUG:-}" == 1 ]]; then
    file="${1:-"$SELF"}" src="${2:-"${SOURCED:-}"}" env="${3:-"$HERE/.env"}"
    msg="[ DEBUG ]: Returning early from '$file' because:\n\n  SOURCED=$src\n\n"
    msg+="[ HINT  ]: Do 'unset SOURCED' or 'SOURCED= ', or otherwise set "
    msg+="'SOURCED' to an empty value in '$env' to run again."
    echo -e "\n$msg\n" >&2
  else return 0; fi
}

# Uncomment, copy, and paste the following lines into the top of each file in
# 'INIT_D', and add 'export SOURCED' at the end to track sourced files:
#
# [[ -n "${BASH_VERSION:-}" ]] && SELF="${BASH_SOURCE[0]}" || SELF="$0"
# [[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
#   SOURCED="${SOURCED#:}:${SELF%:}"
#

[[ "${SOURCED:=}" == *":${SELF}"* ]] && { debug_sourced && return 0; } ||
  SOURCED="${SOURCED#:}:${SELF%:}"

# ------------------------------ Helper Functions ------------------------------

debug_log() {
  local act targ message="$*"
  if [[ "${DEBUG:-}" == 1 ]]; then
    if [[ "$#" -eq 2 ]]; then
      act="$(echo "$1" | tr -s '[:blank:]')"
      targ="$(echo "$2" | tr -s '[:blank:]')"
      echo -e "[ DEBUG ]: - ACTION: '$act'\n[ DEBUG ]:   TARGET: '$targ'"
      return 0
    fi
    echo -e "$message" | tr -s '[:blank:]'
    return 0
  else return 0; fi
}

chown_file() {
  if [[ "${DISABLE_INIT_CHOWN:-}" != 1 ]]; then
    local as_user="${CHOWN_AS:-"$(id -u):$(id -g)"}"
    debug_log "chown $as_user" "$1"
    chown "$as_user" "$1"
  else return 0; fi
}

chmod_file() {
  if [[ "${DISABLE_INIT_CHMOD:-}" != 1 ]]; then
    local mode="${CHMOD_MODE:-"600"}"
    debug_log "chmod $mode" "$1" && chmod "$mode" "$1"
    debug_log "chmod +X" "$1" && chmod "+X" "$1"
  else return 0; fi
}

chownmod() { chown_file "$1" && chmod_file "$1"; }

source_files() {
  for file in "$@"; do
    if [[ -s "$file" && "$file" != *"example"* ]]; then
      debug_log "source" "$file"
      # shellcheck source=/dev/null
      if [[ "$file" == *".env"* ]]; then
        \. "$file" && chownmod "$file"
      else \. "$file"; fi
    fi
  done
}

# --------------------------------- Main Logic ---------------------------------

if [[ "${CREATE_INIT_D:-}" == 1 ]]; then mkdir -p "$INIT_D"; fi
if [[ -d "$INIT_D" ]]; then chownmod "$INIT_D"; fi

DOTENV_SOURCES=()
while IFS= read -r -d '' file; do
  DOTENV_SOURCES+=("$file")
done < <({ find "$HERE" -maxdepth 2 -mindepth 1 -name '*.env' \
  -not -path "**/*env/**" -type f -print0 | sort -z; } 2>/dev/null)

INIT_D_SOURCES=()
while IFS= read -r -d '' file; do
  INIT_D_SOURCES+=("$file")
done < <({ find "$INIT_D" -maxdepth 1 -mindepth 1 \
  -name '*.sh' -type f -print0 | sort -z; } 2>/dev/null)

set -euo pipefail
source_files "${DOTENV_SOURCES[@]}"
source_files "${INIT_D_SOURCES[@]}"
set +euo pipefail

export SOURCED
