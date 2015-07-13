#!/bin/bash

set -euo pipefail

# Copy all files either from local copy (testing) or from github
TRAVIS_UTILS_HOME=/tmp/travis-utils
mkdir -p $TRAVIS_UTILS_HOME
if [ "${1:-}" == "LOCAL" ]; then
  cp -R . $TRAVIS_UTILS_HOME
else
  curl -sSL https://github.com/sonarsource/travis-utils/tarball/master | tar zx --strip-components 1 -C $TRAVIS_UTILS_HOME
fi

# Create shortcuts that are in the PATH
function install_script() {
  echo -e "#!/bin/bash\n\nset -euo pipefail\n\nsource $TRAVIS_UTILS_HOME/commons.sh\n\n$1 \$@" > ~/.local/bin/travis_$1
  chmod u+x ~/.local/bin/travis_$1
}

mkdir -p ~/.local/bin
install_script "runDatabaseCI"
install_script "build_green"
install_script "start_xvfb"
install_script "build"
install_script "download_sonarqube_release"

# Complete the installation
echo "Install jars into local maven repository"
mkdir -p ~/.m2/repository
cp -r /tmp/travis-utils/m2repo/* ~/.m2/repository
