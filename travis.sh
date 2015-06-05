#!/bin/bash

set -euo pipefail

./install.sh
source utils.sh

case "$TESTS" in

PARENT)
  echo "Build the parent poms"
  build_parent_pom "28"
  build_parent_pom "30"
  ;;

ORCHESTRATOR)
  echo "Build orchestrator"
  install_jars
  build_parent_pom "30"
  build_orchestrator "3.2"
  ;;

SONARQUBE_SNAPSHOT)
  echo "Build SonarQube Green Snapshot"
  build_green_sonarqube_snapshot
  ;;

ITS)
  echo "Fetch ITs"
  fetch_its
  ;;

*)
  echo "Invalid TESTS choice [$TESTS]"
  exit 1

esac
