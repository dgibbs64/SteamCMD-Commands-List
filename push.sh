#!/bin/sh

setup_git() {
  git config --global user.email "me@danielgibbs.co.uk"
  git config --global user.name "dgibbs64"
}

commit_website_files() {
  git checkout -b ${TRAVIS_BRANCH}
  git add . steamcmdcommands.txt
  git add . lastchecked.txt
  git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
  git remote add origin https://dgibbs64:${GH_TOKEN}@github.com/dgibbs64/SteamCMD-Commands-List.git
  git push --set-upstream origin ${TRAVIS_BRANCH}
}

setup_git
commit_website_files
upload_files