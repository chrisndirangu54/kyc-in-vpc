#!/bin/bash

set -euo pipefail
set -x

source "$(dirname $0)/env.sh"

EC2_INSTANCE=$("$(dirname $0)/get-container-instance.sh")

IP=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE | jq -r '.Reservations[].Instances[].PrivateIpAddress')

echo $IP
