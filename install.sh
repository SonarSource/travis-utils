#!/bin/sh

TRAVIS_UTILS_HOME=/tmp/travis-utils
mkdir -p $TRAVIS_UTILS_HOME
curl -sSL https://github.com/dgageot/travis-utils/tarball/master | tar zx --strip-components 1 -C $TRAVIS_UTILS_HOME

. $TRAVIS_UTILS_HOME/utils.sh
