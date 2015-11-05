#!/bin/bash

set -euo pipefail

# test of travis tools, this installs the latest travis-utils and run them
# onto few cases

function installTravisTools {
  mkdir ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/$TRAVIS_COMMIT | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

installTravisTools

case "$TEST" in

BUILD_PUBLIC_SNAPSHOT)
  build_snapshot "SonarSource/parent-oss"
  ;;

BUILD_PRIVATE_SNAPSHOT)
  build_snapshot "SonarSource/parent"
  ;;

BUILD_SHA1)
  build "SonarSource/parent-oss" "24"
  ;;

*)
  echo "Unexpected TEST value: $TEST"
  exit 1
  ;;
esac
