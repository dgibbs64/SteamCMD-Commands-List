#!/bin/sh

git config --global user.email "me@danielgibbs.co.uk"
git config --global user.name "dgibbs64"

git remote set-url origin https://dgibbs64:${GH_TOKEN}@github.com/dgibbs64/SteamCMD-Commands-List.git

git checkout ${TRAVIS_BRANCH}
git add . steamcmd_commands.txt
git commit --message "Travis build: $(date +%Y-%m-%d)"
git push --set-upstream origin ${TRAVIS_BRANCH}
