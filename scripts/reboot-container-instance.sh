#!/bin/bash

set -euo pipefail
set -x

source "$(dirname $0)/env.sh"
CONTAINER_INSTANCE=$("$(dirname $0)/get-container-instance.sh")

aws ec2 reboot-instances --instance-ids "$CONTAINER_INSTANCE"
