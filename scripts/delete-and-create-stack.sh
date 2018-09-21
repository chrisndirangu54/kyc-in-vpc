#!/bin/bash

set -x
set -euo pipefail

source "$(dirname $0)/env.sh"

aws cloudformation delete-stack --stack-name "$STACK_NAME"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
"$(dirname $0)/create-or-update-stack.sh"
