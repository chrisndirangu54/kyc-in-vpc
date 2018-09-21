#!/bin/bash

# set -x
set -euo pipefail

source "$(dirname $0)/env.sh"

aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
  | jq -r '.Stacks[].Outputs[] | select(.OutputKey == "EthDNSName").OutputValue'
