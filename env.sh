#!/bin/bash

export TRAVIS_UTILS_HOME=/tmp/travis-utils
export ORCHESTRATOR_CONFIG_URL="file://$TRAVIS_UTILS_HOME/orchestrator.properties"

unset GEM_PATH GEM_HOME RAILS_ENV