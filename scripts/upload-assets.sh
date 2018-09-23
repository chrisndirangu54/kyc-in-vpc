#!/bin/bash

set -x
# set -euo pipefail

source "$(dirname $0)/env.sh"

if [[ ! "$UPLOAD_ASSETS_S3_PATH" ]]
then
  exit 0
fi

aws s3 cp \
  --recursive "$(pwd)/cloudformation/" "s3://$UPLOAD_ASSETS_S3_PATH/" \
  --exclude "*" \
  --include "*.yml"
