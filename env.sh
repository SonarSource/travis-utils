#!/bin/bash

export TRAVIS_UTILS_HOME=/tmp/travis-utils
export ORCHESTRATOR_CONFIG_URL="file://$TRAVIS_UTILS_HOME/orchestrator.properties"
export DISPLAY=:99.0

unset GEM_PATH GEM_HOME RAILS_ENV