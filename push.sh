#!/bin/sh

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_website_files() {
  git checkout -b ${TRAVIS_BRANCH}
  git add . steamcmdcommands.txt
  git add . lastchecked.txt
  git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
  echo "${GH_TOKEN}"
  git remote add origin https://${GH_TOKEN}@github.com/dgibbs64/SteamCMD-Commands-List.git > /dev/null 2>&1
  git push --set-upstream origin ${TRAVIS_BRANCH}
}

setup_git
commit_website_files
upload_files