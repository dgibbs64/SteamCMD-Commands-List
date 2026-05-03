#!/bin/bash
# steamcmd_commands.sh
# Author: Daniel Gibbs
# Website: http://danielgibbs.co.uk
# Version: 250817
# Description: SteamCMD does not have a "list all" command to get all command options within SteamCMD.
# Instead you have use find <string>
# This script outputs all the commands available and saves it to a file

set -euo pipefail

rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
tmpdir="${rootdir}/tmp"

if ! command -v steamcmd > /dev/null 2>&1; then
  echo "Error: steamcmd is not installed or not in PATH."
  exit 1
fi

cleanup() {
  rm -rf "${tmpdir}" "${rootdir}/steamcmd"
}

trap cleanup EXIT

echo ""
echo "Getting SteamCMD Commands/Convars"
echo "================================="
mkdir -p "${tmpdir}"
commands_raw="${tmpdir}/commands_list_raw.txt"
convars_raw="${tmpdir}/convars_list_raw.txt"
# Truncate/create aggregate files
: > "$commands_raw"
: > "$convars_raw"

# Stream processing loop (no per-letter temp files)
for letter in {a..z}; do
  echo "steamcmd +login anonymous +find ${letter} +quit"
  # shellcheck disable=SC2086
  steamcmd +login anonymous +find ${letter} +quit \
    | sed -E -e 's/\x1b\[[0-9;]*m//g' \
      -e '/CWorkThreadPool|workthreadpool.cpp|CProcessWorkItem|CHTTPClientThreadPool|CJobMgr::m_WorkThreadPool:1|Unloading Steam API/d' \
    | awk -v COUT="$commands_raw" -v VOUT="$convars_raw" '
      BEGIN{inConvars=0; inCommands=0}
      /ConVars:/ {inConvars=1; inCommands=0; next}
      /Commands:/ {inConvars=0; inCommands=1; next}
      { if (inConvars) { print >> VOUT } else if (inCommands) { print >> COUT } }
    '
done

# Sorting & de-duplicating lists (single pass each)
echo "Sorting lists."
awk '{$1=$1};1' "${tmpdir}/commands_list_raw.txt" | LC_ALL=C sort -u > "${tmpdir}/commands_list.txt"
awk '{$1=$1};1' "${tmpdir}/convars_list_raw.txt" | LC_ALL=C sort -u > "${tmpdir}/convars_list.txt"

# Final Output
rm "${rootdir}/steamcmd_commands.txt"
touch "${rootdir}/steamcmd_commands.txt"
echo "Generating output."
{
  echo "ConVars:"
  cat "${tmpdir}/convars_list.txt"
  echo ""
  echo "Commands:"
  cat "${tmpdir}/commands_list.txt"
} > "${rootdir}/steamcmd_commands.txt"
cat "${rootdir}/steamcmd_commands.txt"
