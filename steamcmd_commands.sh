#!/bin/bash
# steamcmd_commands.sh
# Author: Daniel Gibbs
# Website: http://danielgibbs.co.uk
# Version: 191212
# Description: SteamCMD does not have a "list all" command to get all command options within SteamCMD.
# Instead you have use find <string>
# This script outputs all the commands available and saves it to a file

rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo ""
echo "Getting SteamCMD Commands/Convars"
echo "================================="
mkdir "${rootdir}/tmp"
cd "${rootdir}/steamcmd" || exit
commands_raw="${rootdir}/tmp/commands_list_raw.txt"
convars_raw="${rootdir}/tmp/convars_list_raw.txt"
# Truncate/create aggregate files
: > "$commands_raw"
: > "$convars_raw"

# Stream processing loop (no per-letter temp files)
for letter in {a..z}; do
  echo "steamcmd +login anonymous +find ${letter} +quit"
  # shellcheck disable=SC2086
  steamcmd +login anonymous +find ${letter} +quit | \
    sed -E -e 's/\x1b\[[0-9;]*m//g' \
      -e '/CWorkThreadPool|workthreadpool.cpp|CProcessWorkItem|CHTTPClientThreadPool|CJobMgr::m_WorkThreadPool:1|CUnloading Steam API/d' | \
    awk -v COUT="$commands_raw" -v VOUT="$convars_raw" '
      BEGIN{inConvars=0; inCommands=0}
      /ConVars:/ {inConvars=1; inCommands=0; next}
      /Commands:/ {inConvars=0; inCommands=1; next}
      { if (inConvars) { print >> VOUT } else if (inCommands) { print >> COUT } }
    '
done

# Removing any remaining ANSI characters.
sed -i 's/\[1m//g' "${rootdir}/tmp/commands_list_raw.txt"
sed -i 's/\[1m//g' "${rootdir}/tmp/convars_list_raw.txt"

# Sorting lists
echo "Sorting lists."
#sort -n "${rootdir}/tmp/commands_list_raw.txt" > "${rootdir}/tmp/commands_list_sort.txt"
sort "${rootdir}/tmp/commands_list_raw.txt" | awk '{$1=$1};1' | tee "${rootdir}/tmp/commands_list_sort.txt"
uniq "${rootdir}/tmp/commands_list_sort.txt" | tee "${rootdir}/tmp/commands_list_uniq.txt"
sort "${rootdir}/tmp/commands_list_uniq.txt" | tee "${rootdir}/tmp/commands_list.txt"

#sort -n "${rootdir}/tmp/convars_list_raw.txt" > "${rootdir}/tmp/convars_list_sort.txt"
sort "${rootdir}/tmp/convars_list_raw.txt" | awk '{$1=$1};1' | tee "${rootdir}/tmp/convars_list_sort.txt"
uniq "${rootdir}/tmp/convars_list_sort.txt" | tee "${rootdir}/tmp/convars_list_uniq.txt"
sort "${rootdir}/tmp/convars_list_uniq.txt" | tee "${rootdir}/tmp/convars_list.txt"

# Final Output
rm "${rootdir}/steamcmd_commands.txt"
touch "${rootdir}/steamcmd_commands.txt"
echo "Generating output."
{
  echo "ConVars:"
  cat "${rootdir}/tmp/convars_list.txt"
  echo ""
  echo "Commands:"
  cat "${rootdir}/tmp/commands_list.txt"
} > "${rootdir}/steamcmd_commands.txt"
cat "${rootdir}/steamcmd_commands.txt"

echo "Tidy up."
rm -rf "${rootdir}/tmp"
rm -rf "${rootdir}/steamcmd"
