#! /usr/bin/env bash

if [[ ! (-a Gemfile.lock) ]]; then
    bundle install
else
    bundle update
fi

bundle exec "$@"
