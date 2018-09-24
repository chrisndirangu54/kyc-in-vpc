#!/bin/bash

set -x
set -euo pipefail

source "$(dirname $0)/env.sh"

cf() {
  aws cloudformation $@
}

ecs() {
  aws ecs $@
}

stop() {
  STACK_NAME="$1"
  OUTPUTS=$(cf describe-stacks --stack-name "$STACK_NAME" | jq -r .Stacks[].Outputs)

  CLUSTER=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="ECSCluster").OutputValue')
  SERVICE=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="ECSService").OutputValue')

  TASK_DEFINITION_NAME=$(ecs describe-services --services "$SERVICE" --cluster "$CLUSTER" \
    | jq -r .services[0].taskDefinition)

  TASK_DEFINITION=$(ecs describe-task-definition \
    --task-def "$TASK_DEFINITION_NAME" | jq '.taskDefinition')

  TASKS=$(ecs list-tasks --service-name "$SERVICE" --cluster $CLUSTER | jq -r .taskArns[])

  for t in $TASKS;
  do
    ecs stop-task --task "$t" --cluster "$CLUSTER"
  done
}

STACK_NAME=${1-"$STACK_NAME"}
stop $STACK_NAME
"$(dirname $0)/update-service.sh" $STACK_NAME
