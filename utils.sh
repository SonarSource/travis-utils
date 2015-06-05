#!/bin/bash

export TRAVIS_UTILS_HOME=/tmp/travis-utils

function reset_ruby {
  unset GEM_PATH GEM_HOME RAILS_ENV
}

function install_jars {
  echo "Install jars into local maven repository"

  mkdir -p ~/.m2/repository
  cp -r $TRAVIS_UTILS_HOME/m2repo/* ~/.m2/repository
}

# Usage: fetch "directory" "user/project" "branch"
function fetch {
  mkdir -p $1
  curl -su dgageot:$ITS_TOKEN -L https://github.com/$2/tarball/$3 | tar zx --strip-components 1 -C $1
}

# Usage: build "directory" "user/project" "branch" "build command" ["FORCE"]
function build {
  echo "Search project [$2:$3] by branch..."
  SHA1=$(curl -su dgageot:$ITS_TOKEN -L https://api.github.com/repos/$2/git/refs/heads/$3 | jq -r .object.sha)
  if [ "$SHA1" == "null" ]; then
    echo "Search project [$2:$3] by tag..."
    SHA1=$(curl -su dgageot:$ITS_TOKEN -L https://api.github.com/repos/$2/git/refs/tags/$3 | jq -r .object.sha)
  fi

  if [ "$SHA1" == "null" ]; then
    echo "Failed to retrieve project [$2:$3]. It may be an authentication failure"
    exit 1
  fi

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

  unset SHA1
}

# Usage: build_sonarqube "BRANCH"
function build_sonarqube {
  build "/tmp/sonarqube_$1" "SonarSource/sonarqube" "$1" "mvn install -DskipTests -Pdev"
}

# Usage: build_parent_pom "VERSION"
function build_parent_pom {
  build "/tmp/parent_$1" "SonarSource/parent" "$1" "mvn install -DskipTests"
}

# Usage: build_orchestrator "VERSION"
function build_orchestrator {
  build "/tmp/orchestrator_$1" "SonarSource/sonar-orchestrator" "$1" "mvn install -DskipTests"
}

# Usage: fetch_its
function fetch_its {
  fetch "/tmp/its" "SonarSource/sonar-tests-languages" "master"
}

# Usage: create_orchestrator_properties
function create_orchestrator_properties {
  PROPERTIES=/tmp/orchestrator.properties

  echo "sonar.jdbc.dialect=embedded" > $PROPERTIES
  echo "orchestrator.updateCenterUrl=http://update.sonarsource.org/update-center-dev.properties" >> $PROPERTIES
  echo "maven.localRepository=${HOME}/.m2/repository" >> $PROPERTIES

  unset PROPERTIES
}

function build_green_sonarqube_snapshot {
  echo "Fetch and build latest green snapshot of SonarQube"

  LAST_GREEN=$(latest_green "SonarSource/sonarqube" "master")
  build_sonarqube "$LAST_GREEN"
}

# Usage: run_its "SONAR_VERSION"
function run_its {
  reset_ruby
  install_jars

  if [ "$1" == "DEV" ]; then
    build_green_sonarqube_snapshot
  fi

  build_parent_pom "28"
  build_parent_pom "30"
  build_orchestrator "3.2"

  fetch_its
  create_orchestrator_properties

  cd /tmp/its
  mvn -f it-java/plugin/pom.xml \
    -Dmaven.test.redirectTestOutputToFile=false \
    -DjavaVersion=DEV \
    -Dsonar.runtimeVersion=$1 \
    -Dorchestrator.configUrl=file:///tmp/orchestrator.properties \
    install
}

# Usage: commit_status "user/project" "COMMIT|BRANCH"
function commit_status {
  curl -sSLu dgageot:$ITS_TOKEN "https://api.github.com/repos/$1/commits/$2/status" | jq -r "[.statuses[] | select(.description==\"The Travis CI build passed\")][1].state"
}

# Usage: latest_green "user/project" "tr  BRANCH"
function latest_green {
  echo "Find latest green version of [$1:$2]"

  for PAGE in 1 2 3 4 5; do
    SHA_LIST=$(curl -sSLu dgageot:$ITS_TOKEN "https://api.github.com/repos/$1/commits?sha=$2&page=$PAGE" | jq -r .[].sha)

    for SHA in $SHA_LIST; do
      STATE=$(commit_status "$1" "$SHA")
      if [ "$STATE" == "success" ]; then
        echo $SHA
        return
      fi
    done
  done

  echo "Couldn't find green commit for [$1:$2]"
}

## Database CI ##

# Usage: buildAndUnzipSonarQubeFromSources
function buildAndUnzipSonarQubeFromSources {
  reset_ruby
  install_jars

  # Build the application
  mvn install -DskipTests -Pdev -Dassembly.format=dir -Dchecksum.failOnError=false
}

# Usage: runDatabaseCI "database" "jdbc_url" "login" "pwd"
function runDatabaseCI {
  buildAndUnzipSonarQubeFromSources

  # Start server
  cd sonar-application/target/sonarqube-*/sonarqube-*
  (exec java -jar lib/sonar-application-*.jar \
    -Dsonar.log.console=true \
    -Dsonar.jdbc.url=$2 -Dsonar.jdbc.username=$3 -Dsonar.jdbc.password=$4 \
    -Dsonar.web.javaAdditionalOpts="-Djava.security.egd=file:/dev/./urandom"
    "$@") &
  pid=$!

  # Wait for server to be up and running
  for i in {1..30}; do
    set +e
    curl -s http://localhost:9000/api/system/status | grep "UP"
    retval=$?
    set -e
    if [ $retval -eq 0 ]; then
      # Success. Let's stop the server
      # Should we use orchestrator's stop command?
      kill -9 $pid

      # Run the tests
      cd ../../..
      mvn -PdbTests package -Dsonar.jdbc.dialect=$1 -Dsonar.jdbc.url=$2 -Dsonar.jdbc.username=$3 -Dsonar.jdbc.password=$4
      exit $?
    fi

    sleep 1
  done

  # Failed to start
  exit 1
}
