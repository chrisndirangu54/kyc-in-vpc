#!/bin/bash

set -euo pipefail

CLEAR='\033[0m'
RED='\033[0;31m'
FROM_ACCOUNT=""
FROM_REGION=""
TO_ACCOUNT=""
TO_REGION=""
IMAGES=""

usage() {
  if [ -n "$1" ]; then
    echo -e "${RED}$1${CLEAR}\n";
  fi

  echo "Usage: $0 --from-account-id awsAccountId --from-region us-east-1 --to-account-id awsAccountId --to-region ap-southeast-1 --images image1,image2,image3"
  echo "  --from-account-id    account id to source ECR images from"
  echo "  --from-region        region source ECR images are in"
  echo "  --to-account-id      account id to copy ECR images to"
  echo "  --to-region          region copy ECR images to"
  echo "  --images             images names comma-delimited list"
  echo ""
  echo "Example: $0 \
    --from-account-id 123 \
    --from-region us-east-1 \
    --to-account-id 456 \
    --to-region ap-southeast-1 \
    --images repo1,repo2,repo3"

  exit 1
}

copy_image() {
  docker pull "$1"
  docker push "$2"
}

while [[ "$#" > 0 ]]; do case $1 in
  --from-account-id) FROM_ACCOUNT="$2"; shift;shift;;
  --from-region) FROM_REGION="$2"; shift;shift;;
  --to-account-id) TO_ACCOUNT="$2"; shift;shift;;
  --to-region) TO_REGION="$2"; shift;shift;;
  --images) IMAGES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1";;
esac; done

if [[ ! $FROM_ACCOUNT ]]
then
  FROM_ACCOUNT=$(aws sts get-caller-identity --output text --query 'Account')
fi

if [[ ! $TO_ACCOUNT ]]
then
  TO_ACCOUNT="$FROM_ACCOUNT"
fi

if [[ ! $IMAGES ]]
then
  IMAGES="tradle-kyc-nginx-proxy,trueface-spoof,roc-face"
fi

if [[ ! $FROM_REGION ]]
then
  FROM_REGION=$(aws configure get region)
fi

if [[ ! $TO_REGION ]]
then
  TO_REGION="$FROM_REGION"
fi

if [[ ! $FROM_ACCOUNT || ! $FROM_REGION || ! $TO_ACCOUNT || ! $TO_REGION || ! $IMAGES ]]
then
  usage "unable to deduce some options"
fi

# convert to array
IFS=',' read -r -a IMAGES <<< "$IMAGES"

`aws ecr get-login --no-include-email`

for name in "${IMAGES[@]}"
do
  FROM_REPO="$FROM_ACCOUNT.dkr.ecr.$FROM_REGION.amazonaws.com/$name"
  TO_REPO="$TO_ACCOUNT.dkr.ecr.$TO_REGION.amazonaws.com/$name"
  if [[ $FROM_REPO == $TO_REPO ]]
  then
    usage "source and destination is the same! Be more specific please!"
  fi

  echo "will copy from $FROM_REPO to $TO_REPO"
  copy_image "$FROM_REPO" "$TO_REPO" &
done

wait
