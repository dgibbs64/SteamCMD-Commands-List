#!/bin/bash
# steamcmdlistcommands.sh
# Author: Daniel Gibbs
# Website: http://danielgibbs.co.uk
# Version: 271215
# Description: SteamCMD does not have a "list all" command to get all command options within SteamCMD.
# Instead you have use find <string>
# This script outputs all the commands available and saves it to a file


rootdir="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
echo ""
echo "Installing SteamCMD"
echo "================================="
cd "${rootdir}"
mkdir -pv "steamcmd"
cd "steamcmd"
if [ ! -f steamcmd.sh ]; then
		echo -e "downloading steamcmd_linux.tar.gz...\c"
		wget -N /dev/null http://media.steampowered.com/client/steamcmd_linux.tar.gz 2>&1 | grep -F HTTP | cut -c45-| uniq
		tar --verbose -zxf steamcmd_linux.tar.gz
		rm -v steamcmd_linux.tar.gz
		chmod +x steamcmd.sh
else
		echo "Steam already installed!"
fi
echo ""
echo "Getting SteamCMD Commands/Convars"
echo "================================="
mkdir "${rootdir}/tmp"
cd "${rootdir}/steamcmd"
for letter in {a..z}
do
    echo "./steamcmd.sh +login anonymous +find ${letter} +quit"
	./steamcmd.sh +login anonymous +find ${letter} +quit > "${rootdir}/tmp/${letter}"
	echo "Creating list for letter ${letter}."
	echo ""
	# Commands List
	cat "${rootdir}/tmp/${letter}" > "${rootdir}/tmp/${letter}commands"
	sed -i '1,/Commands:/d' "${rootdir}/tmp/${letter}commands"
	cat "${rootdir}/tmp/${letter}commands" >> "${rootdir}/tmp/commandslistraw"

	#Convars List
	cat "${rootdir}/tmp/${letter}" > "${rootdir}/tmp/${letter}convars"
	sed -i '1,/ConVars:/d' "${rootdir}/tmp/${letter}convars"
	#cat "${rootdir}/tmp/${letter}convars > "${rootdir}/tmp/${letter}convarscommands
	sed -i '/Commands:/Q' "${rootdir}/tmp/${letter}convars"
	cat "${rootdir}/tmp/${letter}convars" >> "${rootdir}/tmp/convarslistraw"
done
echo "Sorting lists."
cd "${rootdir}/tmp"
sort -n commandslistraw > commandslistsort
uniq commandslistsort > commandslisttidy
cat commandslisttidy|tr -d '\000-\011\013\014\016-\037'| sed 's/\[0m//g'|sed 's/\[1m//g'> commandslist

sort -n convarslistraw > convarslistsort
uniq convarslistsort > convarslisttidy
cat convarslisttidy|tr -d '\000-\011\013\014\016-\037'| sed 's/\[0m//g'|sed 's/\[1m//g'> convarslist
sed -i '/CWorkThreadPool/d' commandslist
sed -i '/CWorkThreadPool/d' convarslist
echo "Generating output."
echo "ConVars:" > "${rootdir}/steamcmdcommands.txt"
cat  "convarslist" >> "${rootdir}/steamcmdcommands.txt"
echo "Commands:" >> "${rootdir}/steamcmdcommands.txt"
cat  "commandslist" >> "${rootdir}/steamcmdcommands.txt"
echo "ConVars:"
cat  "convarslist"
echo "Commands:"
cat  "commandslist"
echo "Tidy up."
rm -rf "${rootdir}/tmp"
rm -rf "${rootdir}/steamcmd"
