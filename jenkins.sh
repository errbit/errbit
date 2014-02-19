#!/bin/bash

set -e

git clean -fdx
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment

bundle exec rake
