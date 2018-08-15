#!/bin/sh

date > lastchecked.txt
cat "lastchecked.txt"
git config --global user.email "me@danielgibbs.co.uk"
git config --global user.name "dgibbs64"

git checkout -b ${TRAVIS_BRANCH}
git add . steamcmdcommands.txt
git add . lastchecked.txt
git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"

git remote set-url origin https://dgibbs64:${GH_TOKEN}@github.com/dgibbs64/SteamCMD-Commands-List.git
git push --set-upstream origin ${TRAVIS_BRANCH}
