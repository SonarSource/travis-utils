#!/bin/bash

set -euo pipefail

# test of travis tools, this installs the latest travis-utils and run them
# onto few cases

function installTravisTools {
  mkdir ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/$TRAVIS_COMMIT | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}

function assertFileContains {
  FILE=$1
  EXPECTED=$2
  if ! grep -q "$EXPECTED" $FILE; then
    echo "File $FILE does not contain '$EXPECTED'"
    echo "Got:"
    cat $FILE
    exit 1
  fi
}

installTravisTools

echo "------ test maven_expression and set_maven_build_version"
cd tests
EXPRESSION=`maven_expression "project.version"`
if [! "$EXPRESSION" = "0.1-SNAPSHOT"]; then
  echo "Got $EXPRESSION instead of 0.1-SNAPSHOT"
  exit 1
fi
set_maven_build_version "1234"
EXPRESSION=`maven_expression "project.version"`
if [! "$EXPRESSION" = "0.1-build1234"]; then
  echo "Got $EXPRESSION instead of 0.1-build1234"
  exit 1
fi
cd -



echo "------- build_snapshot of public project"
LOG_FILE=/tmp/build_public_snapshot.log
build_snapshot "SonarSource/parent-oss" > $LOG_FILE
assertFileContains $LOG_FILE "Get SHA1 of \[SonarSource/parent-oss:HEAD\]"
assertFileContains $LOG_FILE "Build \[SonarSource/parent-oss:"
assertFileContains $LOG_FILE "BUILD SUCCESS"
# reuse cache
echo "------- build_snapshot of public project (new run, to test cache)"
build_snapshot "SonarSource/parent-oss" > $LOG_FILE
assertFileContains $LOG_FILE "Get SHA1 of \[SonarSource/parent-oss:HEAD\]"
assertFileContains $LOG_FILE "is already on cache"



echo "------- build_snapshot of private project"
LOG_FILE=/tmp/build_private_snapshot.log
build_snapshot "SonarSource/parent" > $LOG_FILE
assertFileContains $LOG_FILE "Get SHA1 of \[SonarSource/parent:HEAD\]"
assertFileContains $LOG_FILE "Build \[SonarSource/parent:"
assertFileContains $LOG_FILE "BUILD SUCCESS"
# reuse cache
echo "------- build_snapshot of private project (new run, to test cache)"
build_snapshot "SonarSource/parent" > $LOG_FILE
assertFileContains $LOG_FILE "Get SHA1 of \[SonarSource/parent:HEAD\]"
assertFileContains $LOG_FILE "is already on cache"



echo "------- build sha1"
LOG_FILE=/tmp/build_sha1.log
build "SonarSource/parent-oss" "24" > $LOG_FILE
assertFileContains $LOG_FILE "Build \[SonarSource/parent-oss:24\]"
assertFileContains $LOG_FILE "BUILD SUCCESS"
# reuse cache
echo "------- build sha1 (new run, to test cache)"
build "SonarSource/parent-oss" "24" > $LOG_FILE
assertFileContains $LOG_FILE "is already on cache"
