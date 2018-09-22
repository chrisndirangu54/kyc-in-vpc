#!/bin/bash

set -x
set -euo pipefail

source "$(dirname $0)/env.sh"

read -p "This will DELETE your stack, which is irreversible. Continue (y/n)?" choice
case "$choice" in
  y|Y ) echo "deleting...";;
  n|N ) exit 0;;
  * ) exit 0;;
esac

aws cloudformation delete-stack --stack-name "$STACK_NAME"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
"$(dirname $0)/create-or-update-stack.sh"
