#! /usr/bin/env bash

if [[ (-z "${AWS_ACCESS_KEY_ID}") && \
      (-z "${AWS_SECRET_ACCESS_KEY}") && \
      (-z "${AWS_BUCKET}") ]]; then
  echo "AWS environment unknown; skipping deployment"
  exit 0
fi

SUPPORTED_BRANCH=${SUPPORTED_BRANCH:-master}
if [[ ( "$TRAVIS" == "true" ) && \
      ( "$TRAVIS_BRANCH" != "$SUPPORTED_BRANCH" )]]; then
  echo "Travis-CI branch not supported; skipping deployment"
  exit 0
fi

s3_website push
