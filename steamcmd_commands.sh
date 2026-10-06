#!/bin/bash
# steamcmd_commands.sh
# Author: Daniel Gibbs
# Website: https://danielgibbs.co.uk
# Description: SteamCMD does not have a "list all" command to get all command options within SteamCMD.
# Instead you have to use find <string>.
# This script outputs all the commands available and saves it to a file.

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

# Record the SteamCMD version from its startup banner, e.g.
# "Steam Console Client (c) Valve Corporation - version 1788292693".
version="$({ steamcmd +quit || true; } | sed -nE '/Steam Console Client/{s/.* version ([0-9]+).*/\1/p;q}')"
if [ -n "${version}" ]; then
  echo "SteamCMD version: ${version}"
  echo "${version}" > "${rootdir}/steamcmd_version.txt"
else
  echo "Warning: could not detect SteamCMD version" >&2
fi

# "find" matches a substring of command/convar names and descriptions and has
# no wildcard, so search for every letter in a single SteamCMD session.
find_args=()
for letter in {a..z}; do
  find_args+=("+find ${letter}")
done
echo "steamcmd +login anonymous +find a ... +find z +quit"
# SteamCMD exit codes are unreliable, so check the output instead.
{ steamcmd +login anonymous "${find_args[@]}" +quit || true; } \
  | sed -E -e 's/\x1b\[[0-9;]*m//g' \
    -e '/CWorkThreadPool|workthreadpool.cpp|CProcessWorkItem|CHTTPClientThreadPool|CJobMgr::m_WorkThreadPool:1|Unloading Steam API/d' \
  | awk -v COUT="${commands_raw}" -v VOUT="${convars_raw}" '
    BEGIN { section = ""; printf "" > COUT; printf "" > VOUT }
    /^ *ConVars: *\r?$/ { section = "convars"; next }
    /^ *Commands: *\r?$/ { section = "commands"; next }
    /^ *(OK)? *\r?$/ { next }
    section == "convars" { print > VOUT }
    section == "commands" { print > COUT }
  '

# Sorting & de-duplicating lists
echo "Sorting lists."
awk '{$1=$1};1' "${commands_raw}" | LC_ALL=C sort -u > "${tmpdir}/commands_list.txt"
awk '{$1=$1};1' "${convars_raw}" | LC_ALL=C sort -u > "${tmpdir}/convars_list.txt"

if [ ! -s "${tmpdir}/commands_list.txt" ] || [ ! -s "${tmpdir}/convars_list.txt" ]; then
  echo "Error: no commands or convars found; not updating steamcmd_commands.txt" >&2
  exit 1
fi

# Final Output
echo "Generating output."
{
  echo "ConVars:"
  cat "${tmpdir}/convars_list.txt"
  echo ""
  echo "Commands:"
  cat "${tmpdir}/commands_list.txt"
} > "${rootdir}/steamcmd_commands.txt"
cat "${rootdir}/steamcmd_commands.txt"
echo ""
echo "Found $(wc -l < "${tmpdir}/convars_list.txt") convars and $(wc -l < "${tmpdir}/commands_list.txt") commands."
