#!/bin/bash
# summarise_changes.sh
# Description: Describe changes to the generated SteamCMD output. Prepends an
# entry to CHANGELOG.md and outputs a commit message. Outputs an empty message
# if nothing changed.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

changelog="CHANGELOG.md"
output="steamcmd_commands.txt"
version="$(cat steamcmd_version.txt 2> /dev/null || true)"
version="${version:-unknown}"
max_names=25

# Include new, untracked output files in git diff.
git add --intent-to-add -- "${output}" steamcmd_version.txt 2> /dev/null || true

# Names of entries on removed (-) and added (+) lines, e.g. "@sSteamCmdForcePlatformType".
names() {
  git diff -U0 -- "${output}" \
    | awk -v sign="${1}" '
      substr($0, 1, 1) == sign && substr($0, 1, 3) != sign sign sign {
        split(substr($0, 2), field, " ")
        if (field[1] != "" && field[1] !~ /^(ConVars|Commands):$/) print field[1]
      }
    ' \
    | LC_ALL=C sort -u
}

version_changed=false
if ! git diff --quiet -- steamcmd_version.txt; then
  version_changed=true
fi

added=()
removed=()
changed=()
if ! git diff --quiet -- "${output}"; then
  mapfile -t added < <(LC_ALL=C comm -13 <(names -) <(names +))
  mapfile -t removed < <(LC_ALL=C comm -23 <(names -) <(names +))
  mapfile -t changed < <(LC_ALL=C comm -12 <(names -) <(names +))
fi

# list_names <label> <names...>
list_names() {
  local label="${1}"
  shift
  [ "$#" -eq 0 ] && return 0
  local shown=("${@:1:${max_names}}")
  local more=""
  if [ "$#" -gt "${max_names}" ]; then
    more=" and $(($# - max_names)) more"
  fi
  local joined
  # shellcheck disable=SC2016 # literal backticks for Markdown
  joined="$(printf '`%s`, ' "${shown[@]}")"
  echo "- ${label} ($#): ${joined%, }${more}"
}

total=$((${#added[@]} + ${#removed[@]} + ${#changed[@]}))
message=""
if [ "${total}" -gt 0 ]; then
  summary=()
  [ "${#added[@]}" -gt 0 ] && summary+=("${#added[@]} added")
  [ "${#removed[@]}" -gt 0 ] && summary+=("${#removed[@]} removed")
  [ "${#changed[@]}" -gt 0 ] && summary+=("${#changed[@]} changed")
  summary_text="$(IFS=,; echo "${summary[*]}")"
  summary_text="${summary_text//,/, }"
  if [ "${total}" -le 3 ]; then
    message="SteamCMD commands: ${summary_text} ($(printf '%s ' "${added[@]}" "${removed[@]}" "${changed[@]}" | sed 's/ $//')) (version ${version})"
  else
    message="SteamCMD commands: ${summary_text} (version ${version})"
  fi
elif ! git diff --quiet -- "${output}"; then
  message="SteamCMD commands list reformatted (version ${version})"
elif [ "${version_changed}" = true ]; then
  message="SteamCMD updated to version ${version} (commands unchanged)"
fi

if [ -n "${message}" ]; then
  entry="$(mktemp)"
  {
    echo "## $(date -u +%Y-%m-%d) - SteamCMD version ${version}"
    echo ""
    if [ "${total}" -eq 0 ]; then
      if git diff --quiet -- "${output}"; then
        echo "- SteamCMD version changed; commands and convars unchanged"
      else
        echo "- Formatting changes only; no commands or convars added, removed or changed"
      fi
    fi
    list_names "Added" "${added[@]}"
    list_names "Removed" "${removed[@]}"
    list_names "Changed" "${changed[@]}"
    echo ""
  } > "${entry}"

  if [ -f "${changelog}" ]; then
    # Insert the new entry after the header (first two lines).
    {
      head -n 2 "${changelog}"
      cat "${entry}"
      tail -n +3 "${changelog}"
    } > "${changelog}.tmp"
    mv "${changelog}.tmp" "${changelog}"
  else
    {
      echo "# Changelog"
      echo ""
      cat "${entry}"
    } > "${changelog}"
  fi
  rm -f "${entry}"
  sed -n '1,20p' "${changelog}"
fi

echo "message: ${message:-<none>}"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "message=${message}" >> "${GITHUB_OUTPUT}"
fi
