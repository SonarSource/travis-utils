#!/bin/bash

set -euo pipefail

function installTravisTools {
  mkdir ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/$TRAVIS_COMMIT | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

installTravisTools

case "$TESTS" in

SONARQUBE_SNAPSHOT)
  build_snapshot "SonarSource/sonarqube"
  ;;

SONAR_DB_COPY_SNAPSHOT)
  build "SonarSource/parent" "30"
  build_snapshot "SonarSource/sonar-db-copy"
  ;;

SONAR_DB_COPY)
  build "SonarSource/parent" "30"
  build "SonarSource/sonar-db-copy"
  ;;

esac
