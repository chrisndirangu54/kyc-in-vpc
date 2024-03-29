#!/bin/bash

set -x
set -euo pipefail

source "$(dirname $0)/env.sh"

# relative to build-params.js script
PARAMS_FILE=${1-"../cloudformation/stack-parameters.json"}

CF_DIR="$(dirname $0)/../cloudformation"

"$(dirname $0)/validate-templates.sh"
"$(dirname $0)/upload-assets.sh"

PARAMETERS=$(node scripts/build-params.js "$PARAMS_FILE" "$UPLOAD_ASSETS_S3_PATH")
EXISTING_STACKS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" || echo '{"Stacks": []}')

EXISTING_STACK=$(echo $EXISTING_STACKS |
  jq -r '[.Stacks[] | select(.StackStatus!="DELETE_COMPLETE")][0].StackId')

echo "EXISTING_STACK: $EXISTING_STACK"

if [ "$EXISTING_STACK" == "" ] || [ "$EXISTING_STACK" == "null" ];
then
  echo 'creating stack!'
  aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$CF_DIR/main.yml" \
    --parameters "$PARAMETERS" \
    --capabilities CAPABILITY_NAMED_IAM \
    --disable-rollback \
    --timeout 120000

  echo "waiting for stack to finish creating..."
  aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME"
else
  echo "creating stack $STACK_NAME"
  aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$CF_DIR/main.yml" \
    --parameters "$PARAMETERS" \
    --capabilities CAPABILITY_NAMED_IAM

  echo "waiting for stack to finish updating..."
  aws cloudformation wait stack-update-complete \
    --stack-name "$STACK_NAME"
fi

