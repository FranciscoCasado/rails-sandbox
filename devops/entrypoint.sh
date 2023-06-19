#!/bin/bash

# Bail run on process fail
set -o errexit
set -o nounset

# Handle sigterm gracefully
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143;
}

trap term_handler TERM

if [ "${RAILS_ENV}" = "development" ]
then
    echo "Installing dependencies..."
    bundle install
    yarn install

    echo "Starting development server..."
    until rails s -b "0.0.0.0"; do
        echo "Development server crashed... restarting" >&2
        sleep 3;
    done
else
    if [ "${RELEASE_IN_DEPLOY}" = "true" ]
    then
      source ./devops/bin/release.sh
    fi
    if [ -f .git_commit_hash ]; then
      export GIT_COMMIT_HASH=$(head -n 1 .git_commit_hash)
    fi
    bundle exec puma -C ./config/puma.rb
fi
