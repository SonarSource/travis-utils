#!/bin/bash

function reset_ruby() {
	unset GEM_PATH GEM_HOME RAILS_ENV
}

function install_jars() {
  echo "Install jars into local maven repository"

  mkdir -p ~/.m2/repository
  cp -r m2repo/* ~/.m2/repository
}

# usage: fetch "directory" "user/project" "branch"
function fetch() {
  mkdir -p $1
  curl -su dgageot:$ITS_TOKEN -L https://github.com/$2/tarball/$3 | tar zx --strip-components 1 -C $1
}

# usage: build "directory" "user/project" "branch" "build command" ["FORCE"]
function build() {
  SHA1=$(curl -su dgageot:$ITS_TOKEN -L https://api.github.com/repos/$2/git/refs/heads/$3 | jq -r .object.sha)

  if [ -f "$HOME/.m2/repository/$SHA1" ]; then
    echo "Project [$2:$3] with sha1 [$SHA1] is already on cache"
  else
    echo "Fetch and build project [$2:$3]"
    fetch $1 $2 $3
    cd $1
    $4
    cd -
  fi

  if [ "${5:-}" != "FORCE" ]; then
    echo "OK" > $HOME/.m2/repository/$SHA1
  fi
}