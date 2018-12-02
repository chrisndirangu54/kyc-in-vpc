#!/bin/bash

set -euo pipefail
set -x

source "$(dirname "$0")/env.sh"

EC2_INSTANCE=$("$(dirname $0)/get-container-instance.sh")
aws ec2 get-console-output --instance-id "$EC2_INSTANCE" | jq -r .Output
