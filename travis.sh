#!/bin/bash

set -euo pipefail

./install.sh "LOCAL"
source /tmp/travis-utils/env.sh

case "$TESTS" in


  install_script "runDatabaseCI"
  install_script "sonarqube_its"
  install_script "build_green"
  install_script "start_xvfb"
  install_script "build"
  install_script "download_sonarqube_release"

SONARQUBE_SNAPSHOT)
  echo "Build sonarqube Green Snapshot"
  travis_build_green "SonarSource/sonarqube" "master"
  ;;

SONAR_CPP_SNAPSHOT)
  echo "Build sonar-cpp Green Snapshot"
  travis_build "SonarSource/sonar-license" "2.9"
  travis_build_green "SonarSource/sonar-cpp" "master"
  ;;

*)
  echo "Invalid TESTS choice [$TESTS]"
  exit 1

esac
