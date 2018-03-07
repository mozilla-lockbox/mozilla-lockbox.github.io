#! /usr/bin/env bash

aws configure set preview.cloudfront true

if [[ (-z "${AWS_DISTRIBUTION_ID}") ]] ; then
  echo "missing distribution id; bypassing."
  exit 0
fi

echo "invalding cloudfront ..."
AWS_INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id=${AWS_DISTRIBUTION_ID} \
  --paths '/*' | jq -r '.Invalidation.Id')

aws cloudfront wait invalidation-completed \
  --distribution-id=${AWS_DISTRIBUTION_ID} \
  --id ${AWS_INVALIDATION_ID}
echo ".. complete!"
