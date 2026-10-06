#!/bin/bash
# commit_message.sh
# Description: Describe changes to the generated SteamCMD output as a commit
# message, listing added/removed/changed commands and convars in the body.
# Outputs an empty message if nothing changed.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

output="steamcmd_commands.txt"
version="$(cat steamcmd_version.txt 2> /dev/null || true)"
version="${version:-unknown}"

# Include new, untracked output files in git diff.
git add --intent-to-add -- "${output}" steamcmd_version.txt 2> /dev/null || true

# Names of entries on removed (-) or added (+) lines, e.g. "@sSteamCmdForcePlatformType".
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

added=()
removed=()
changed=()
if ! git diff --quiet -- "${output}"; then
  mapfile -t added < <(LC_ALL=C comm -13 <(names -) <(names +))
  mapfile -t removed < <(LC_ALL=C comm -23 <(names -) <(names +))
  mapfile -t changed < <(LC_ALL=C comm -12 <(names -) <(names +))
fi

total=$((${#added[@]} + ${#removed[@]} + ${#changed[@]}))
title=""
body=""
if [ "${total}" -gt 0 ]; then
  summary=()
  [ "${#added[@]}" -gt 0 ] && summary+=("${#added[@]} added")
  [ "${#removed[@]}" -gt 0 ] && summary+=("${#removed[@]} removed")
  [ "${#changed[@]}" -gt 0 ] && summary+=("${#changed[@]} changed")
  summary_text="$(printf '%s, ' "${summary[@]}")"
  summary_text="${summary_text%, }"
  if [ "${total}" -le 3 ]; then
    names_text="$(printf '%s ' "${added[@]}" "${removed[@]}" "${changed[@]}")"
    title="SteamCMD commands: ${summary_text} (${names_text% }) (version ${version})"
  else
    title="SteamCMD commands: ${summary_text} (version ${version})"
  fi
  [ "${#added[@]}" -gt 0 ] && body+="Added: ${added[*]}"$'\n'
  [ "${#removed[@]}" -gt 0 ] && body+="Removed: ${removed[*]}"$'\n'
  [ "${#changed[@]}" -gt 0 ] && body+="Changed: ${changed[*]}"$'\n'
elif ! git diff --quiet -- "${output}"; then
  title="SteamCMD commands list reformatted (version ${version})"
elif ! git diff --quiet -- steamcmd_version.txt; then
  title="SteamCMD updated to version ${version} (commands unchanged)"
fi

message="${title}"
if [ -n "${body}" ]; then
  message+=$'\n\n'"${body%$'\n'}"
fi

echo "message: ${message:-<none>}"
if [ -n "${GITHUB_OUTPUT:-}" ] && [ -z "${message}" ]; then
  echo "message=" >> "${GITHUB_OUTPUT}"
elif [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "message<<COMMIT_MESSAGE_EOF"
    echo "${message}"
    echo "COMMIT_MESSAGE_EOF"
  } >> "${GITHUB_OUTPUT}"
fi
