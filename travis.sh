#!/bin/bash

set -euo pipefail

./install.sh "LOCAL"

case "$TESTS" in

SONARQUBE_SNAPSHOT)
  echo "Build sonarqube Green Snapshot"
  travis_build_green_sonarqube_snapshot
  ;;

SONAR_CPP_SNAPSHOT)
  echo "Build sonar-cpp Green Snapshot"
  travis_install_jars
  travis_build "SonarSource/sonar-license" "2.9"
  travis_build_green "SonarSource/sonar-cpp" "master"
  ;;

RUN_PLUGIN_ITS_DEV)
  echo "Run ITs on DEV version"
  cp -r test/its its
  travis_run_plugin_its "IT-DEV"
  ;;

RUN_PLUGIN_ITS_LATEST)
echo "Run ITs on LATEST version"
  cp -r test/its its
  travis_run_plugin_its "IT-LATEST"
  ;;

*)
  echo "Invalid TESTS choice [$TESTS]"
  exit 1

esac
