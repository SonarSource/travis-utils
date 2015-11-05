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

SONAR_CPP_SNAPSHOT)
  build "SonarSource/parent" "31"
  build "SonarSource/sonar-license" "2.9"

  build "SonarSource/parent" "31"
  build_snapshot "SonarSource/sonar-cpp"
  ;;

SONAR_VIEWS_SNAPSHOT)
  build_snapshot "SonarSource/sonar-views"
  ;;

SONAR_VIEWS)
  build "SonarSource/sonar-views" "31"
  ;;

esac
