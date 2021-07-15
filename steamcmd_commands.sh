#!/bin/bash
# steamcmd_commands.sh
# Author: Daniel Gibbs
# Website: http://danielgibbs.co.uk
# Version: 191212
# Description: SteamCMD does not have a "list all" command to get all command options within SteamCMD.
# Instead you have use find <string>
# This script outputs all the commands available and saves it to a file

rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Install SteamCMD
echo ""
echo "Installing SteamCMD"
echo "================================="
cd "${rootdir}" || exit
mkdir -pv "steamcmd"
cd "steamcmd" || exit
if [ ! -f "steamcmd.sh" ]; then
    echo -e "downloading steamcmd_linux.tar.gz...\c"
    wget -N /dev/null http://media.steampowered.com/client/steamcmd_linux.tar.gz 2>&1 | grep -F HTTP | cut -c45-| uniq
    tar --verbose -zxf "steamcmd_linux.tar.gz"
    rm -v "steamcmd_linux.tar.gz"
    chmod +x "steamcmd.sh"
else
    echo "Steam already installed!"
fi

echo ""
echo "Getting SteamCMD Commands/Convars"
echo "================================="
mkdir "${rootdir}/tmp"
cd "${rootdir}/steamcmd" || exit
# Loop though each letter of the alphabet using find command
for letter in {a..z}
do
    echo "./steamcmd.sh +login anonymous +find ${letter} +quit"
    ./steamcmd.sh +login anonymous +find ${letter} +quit > "${rootdir}/tmp/${letter}_raw.txt"
    # Remove ANSI characters
    sed -i 's/\x1b//g' "${rootdir}/tmp/${letter}_raw.txt"
    sed -i 's/\[0m//g' "${rootdir}/tmp/${letter}_raw.txt"
    sed -i 's/\[1m//g' "${rootdir}/tmp/${letter}_raw.txt"
    # Remove CWorkThreadPool errors
    sed -i '/CWorkThreadPool/d' "${rootdir}/tmp/${letter}_raw.txt"
    sed -i '/workthreadpool.cpp/d' "${rootdir}/tmp/${letter}_raw.txt"
    sed -i '/CProcessWorkItem/d' "${rootdir}/tmp/${letter}_raw.txt"
    
    # Separating commands and convars
    # Commands List
    cat "${rootdir}/tmp/${letter}_raw.txt" > "${rootdir}/tmp/${letter}_commands.txt"
    sed -i '1,/Commands:/d' "${rootdir}/tmp/${letter}_commands.txt"
    cat "${rootdir}/tmp/${letter}_commands.txt" >> "${rootdir}/tmp/commands_list_raw.txt"

    # Convars List
    cat "${rootdir}/tmp/${letter}_raw.txt" > "${rootdir}/tmp/${letter}convars"
    sed -i '1,/ConVars:/d' "${rootdir}/tmp/${letter}convars"
    sed -i '/Commands:/Q' "${rootdir}/tmp/${letter}convars"
    cat "${rootdir}/tmp/${letter}convars" >> "${rootdir}/tmp/convars_list_raw.txt"
done

# Removing any remaining ANSI characters.
sed -i 's/\[1m//g' "${rootdir}/tmp/commands_list_raw.txt"
sed -i 's/\[1m//g' "${rootdir}/tmp/convars_list_raw.txt"

# Sorting lists
echo "Sorting lists."
#sort -n "${rootdir}/tmp/commands_list_raw.txt" > "${rootdir}/tmp/commands_list_sort.txt"
#sort "${rootdir}/tmp/commands_list_raw.txt" | tee "${rootdir}/tmp/commands_list_sort.txt"
#uniq "${rootdir}/tmp/commands_list_sort.txt" | tee "${rootdir}/tmp/commands_list.txt"


uniq "${rootdir}/tmp/commands_list_raw.txt" | tee "${rootdir}/tmp/commands_list_uniq.txt"
sort "${rootdir}/tmp/commands_list_uniq.txt" | tee "${rootdir}/tmp/commands_list.txt"

#sort -n "${rootdir}/tmp/convars_list_raw.txt" > "${rootdir}/tmp/convars_list_sort.txt"
#sort "${rootdir}/tmp/convars_list_raw.txt" | tee "${rootdir}/tmp/convars_list_sort.txt"
#uniq "${rootdir}/tmp/convars_list_sort.txt" | tee "${rootdir}/tmp/convars_list.txt"

uniq "${rootdir}/tmp/convars_list_raw.txt" | tee "${rootdir}/tmp/convars_list_uniq.txt"
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
cat  "${rootdir}/tmp/commands_list.txt"
} > "${rootdir}/steamcmd_commands.txt"
cat "${rootdir}/steamcmd_commands.txt"

echo "Tidy up."
rm -rf "${rootdir}/tmp"
rm -rf "${rootdir}/steamcmd"
