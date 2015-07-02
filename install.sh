#!/bin/bash

set -euo pipefail

TRAVIS_UTILS_HOME=/tmp/travis-utils

function install_script() {
  echo -e "#!/bin/bash\n\nset -euo pipefail\n\nsource $TRAVIS_UTILS_HOME/commons.sh\n\n$1 \$@" > ~/.local/bin/travis_$1
  chmod u+x ~/.local/bin/travis_$1
}

mkdir -p $TRAVIS_UTILS_HOME

if [ "${1:-}" == "LOCAL" ]; then
  cp -R . $TRAVIS_UTILS_HOME
else
  curl -sSL https://github.com/sonarsource/travis-utils/tarball/v3 | tar zx --strip-components 1 -C $TRAVIS_UTILS_HOME
fi

mkdir -p ~/.local/bin
install_script "build_green_sonarqube_snapshot"
install_script "run_its"
install_script "runDatabaseCI"
install_script "install_jars"
install_script "sonarqube_its"
