#!/bin/bash

function reset_ruby {
  unset GEM_PATH GEM_HOME RAILS_ENV
}

function install_jars {
  echo "Install jars into local maven repository"

  mkdir -p ~/.m2/repository
  cp -r /tmp/travis-utils/m2repo/* ~/.m2/repository
}

# Usage: fetch "directory" "user/project" "branch"
function fetch {
  mkdir -p $1
  curl -ssL https://github.com/$2/tarball/$3 | tar zx --strip-components 1 -C $1
}

# Usage build_sha1 "directory" "user/project" "sha1" "build command"
function build_sha1 {
  SHA1=$3

  if [ -f "$HOME/.m2/repository/$2/$SHA1" ]; then
    echo "Project [$2] with sha1 [$SHA1] is already on cache"
  else
    echo "Fetch [$2:$SHA1]"
    fetch $1 $2 $SHA1

    echo "Build [$2:$SHA1]"
    cd $1
    $4
    cd -
  fi

  rm -Rf $HOME/.m2/repository/$2
  mkdir -p $HOME/.m2/repository/$2
  echo "OK" > $HOME/.m2/repository/$2/$SHA1

  unset SHA1
}

# Usage: build_green_sonarqube_snapshot
function build_green_sonarqube_snapshot {
  build_green "SonarSource/sonarqube" "master"
}

# Usage: build_green "user/project" "branch"
function build_green {
  echo "Fetch and build latest green snapshot of [$1:$2]"

  LAST_GREEN=$(latest_green "$1")

  build_sha1 "/tmp/sonarqube_$2" "$1" "$LAST_GREEN" "mvn install -DskipTests -Pdev"

  unset LAST_GREEN
}

# Usage: run_its "SONAR_VERSION" ["DEP1"] ["DEP2"]
function run_its {
  reset_ruby
  install_jars

  # Build dependencies and collect options
  OPTIONS=""
  for PARAM in "${@:2}"; do
    if [ "${PARAM:0:1}" != '-' ]; then
      build_green "$PARAM" "master"
    else
      OPTIONS="$OPTIONS $PARAM"
    fi
  done

  if [ "$1" == "IT-DEV" ]; then
    VERSION="DEV"

    build_green "SonarSource/sonarqube" "master"
  else
    VERSION="5.1.1"

    echo "Downloading latest SonarQube release [$1]..."
    mkdir -p ~/.m2/repository/org/codehaus/sonar/sonar-application/$VERSION
    curl -sSL http://downloads.sonarsource.com/sonarqube/sonarqube-$VERSION.zip -o ~/.m2/repository/org/codehaus/sonar/sonar-application/$VERSION/sonar-application-$VERSION.zip
  fi

  cd its/plugin
  mvn -Dmaven.test.redirectTestOutputToFile=false -Dsonar.runtimeVersion="$VERSION" test $OPTIONS

  unset VERSION
}

# Usage: start_xvfb
function start_xvfb {
  export DISPLAY=:99.0
  sh -e /etc/init.d/xvfb start
}

# Usage: sonarqube_its "category"
function sonarqube_its {
  reset_ruby
  install_jars
  start_xvfb

  mvn install -Pit -DskipTests -Dsonar.runtimeVersion=DEV -Dorchestrator.configUrl=file://$(pwd)/it/orchestrator.properties -Dcategory="$1"
}

# Usage: latest_green "user/project"
function latest_green {
  curl -sSL http://sonarsource-979.appspot.com/$1/latestGreen
}

# Usage: runDatabaseCI "database" "jdbc_url" "login" "pwd"
function runDatabaseCI {
  # Build current version of SonarQube (Don't create a zip)
  mvn install -DskipTests -Pdev -Dassembly.format=dir -Dchecksum.failOnError=false -T2 -Dsource.skip=true

  # Start server
  reset_ruby
  cd sonar-application/target/sonarqube-*/sonarqube-*
  (exec java -jar lib/sonar-application-*.jar \
    -Dsonar.log.console=true \
    -Dsonar.jdbc.url=$2 -Dsonar.jdbc.username=$3 -Dsonar.jdbc.password=${4:-} \
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
      install_jars
      cd ../../..
      mvn -PdbTests package -Dsonar.jdbc.dialect=$1 -Dsonar.jdbc.url=$2 -Dsonar.jdbc.username=$3 -Dsonar.jdbc.password=${4:-}
      exit $?
    fi

    sleep 1
  done

  # Failed to start
  exit 1
}
