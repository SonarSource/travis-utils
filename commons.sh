#!/bin/bash

# Usage: fetch "directory" "user/project" "branch"
function fetch {
  mkdir -p $1

  if [ "${GITHUB_TOKEN:-}" == "" ]; then
    curl -ssL https://github.com/$2/tarball/$3 | tar zx --strip-components 1 -C $1
  else
    curl -ssL https://$GITHUB_TOKEN@github.com/$2/tarball/$3 | tar zx --strip-components 1 -C $1
  fi
}

# Usage build "user/project" "sha1"
function build {
  SHA1=$2
  DIRECTORY="/tmp/$1/$2"

  if [ -f "$HOME/.m2/repository/$1/$SHA1" ]; then
    echo "Project [$1] with sha1 [$SHA1] is already on cache"
  else
    echo "Fetch [$1:$SHA1]"
    fetch $DIRECTORY $1 $SHA1

    echo "Build [$1:$SHA1]"
    cd $DIRECTORY
    mvn install -DskipTests -Pdev
    cd -

    rm -Rf $HOME/.m2/repository/$2
    mkdir -p $HOME/.m2/repository/$2
    echo "OK" > $HOME/.m2/repository/$2/$SHA1
  fi

  unset SHA1 DIRECTORY
}

# Usage: build_green "user/project" "branch"
function build_green {
  echo "Fetch and build latest green snapshot of [$1:$2]"

  LAST_GREEN_SHA1=$(curl -sSL http://sonarsource-979.appspot.com/$1/latestGreen)

  build "$1" "$LAST_GREEN_SHA1"

  unset LAST_GREEN_SHA1
}

# Usage: download_sonarqube_release "VERSION"
function download_sonarqube_release {
  echo "Downloading latest SonarQube release [$1]..."
  mkdir -p ~/.m2/repository/org/codehaus/sonar/sonar-application/$1
  curl -sSL http://downloads.sonarsource.com/sonarqube/sonarqube-$1.zip -o ~/.m2/repository/org/codehaus/sonar/sonar-application/$1/sonar-application-$1.zip
}

# Usage: start_xvfb
function start_xvfb {
  /sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -ac -screen 0 1280x1024x16
}

# Usage: runDatabaseCI "database" "jdbc_url" "login" "pwd"
function runDatabaseCI {
  # Build current version of SonarQube (Don't create a zip)
  mvn install -DskipTests -Pdev -Dassembly.format=dir -Dchecksum.failOnError=false -T2 -Dsource.skip=true

  # Start server
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
      cd ../../../..
      mvn package -pl :sonar-db -am -PdbTests -Dsonar.jdbc.dialect=$1 -Dsonar.jdbc.url=$2 -Dsonar.jdbc.username=$3 -Dsonar.jdbc.password=${4:-} -V
      exit $?
    fi

    sleep 1
  done

  # Failed to start
  exit 1
}
