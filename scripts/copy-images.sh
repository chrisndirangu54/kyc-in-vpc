#!/bin/bash

set -euo pipefail

CLEAR='\033[0m'
RED='\033[0;31m'
FROM_PROFILE=""
FROM_ACCOUNT=""
FROM_REGION=""
TO_PROFILE=""
TO_ACCOUNT=""
TO_REGION=""
IMAGES=""

usage() {
  if [ -n "$1" ]; then
    echo -e "${RED}$1${CLEAR}\n";
  fi

  echo "Usage: $0 --from-profile awsAccountId --from-region us-east-1 --to-profile awsAccountId --to-region ap-southeast-1 --images image1,image2,image3"
  echo "  --from-profile       local AWS profile to use to pull ECR images"
  echo "  --from-region        region source ECR images are in"
  echo "  --to-profile         local AWS profile to use to push ECR images"
  echo "  --to-region          region copy ECR images to"
  echo "  --images             images names comma-delimited list"
  echo ""
  echo "Example: $0 \
    --from-profile myprofile \
    --from-region us-east-1 \
    --to-profile myotherprofile \
    --to-region ap-southeast-1 \
    --images repo1,repo2,repo3"

  exit 1
}

require() {
    command -v "$1" > /dev/null 2>&1 || {
        echo "Some of the required software is not installed:"
        echo "    please install $1" >&2;
        exit 4;
    }
}

get_repo_url() {
  REPO_NAME=$1
  OUT=$(aws --profile "$TO_PROFILE" ecr describe-repositories --repository-name=$REPO_NAME 2> /dev/null || echo "{}")
  echo $OUT | jq -r ".repositories[0].repositoryUri"
}

create_repo() {
  REPO_NAME=$1
  REPO_URL=$(get_repo_url $REPO_NAME)
  if [ $REPO_URL != "null" ]; then
    echo "Repository already exists"
    return 0
  fi

  echo "Creating ECR repository $REPO_NAME"
  aws ecr create-repository --repository-name $REPO_NAME --region $TO_REGION
}

copy_image() {
  NAME="$1"
  FROM_REPO="$FROM_ACCOUNT.dkr.ecr.$FROM_REGION.amazonaws.com/$NAME"
  TO_REPO="$TO_ACCOUNT.dkr.ecr.$TO_REGION.amazonaws.com/$NAME"

  echo "will copy from $FROM_REPO to $TO_REPO"

  `aws --profile "$FROM_PROFILE" ecr get-login --no-include-email --region $FROM_REGION`

  docker pull "$FROM_REPO"
  docker tag "$FROM_REPO" "$TO_REPO"

  `aws  --profile "$TO_PROFILE" ecr get-login --no-include-email --region $TO_REGION`
  create_repo "$NAME"
  docker push "$TO_REPO"
}

require jq

while [[ "$#" > 0 ]]; do case $1 in
  --from-profile) FROM_PROFILE="$2"; shift;shift;;
  --from-region) FROM_REGION="$2"; shift;shift;;
  --to-profile) TO_PROFILE="$2"; shift;shift;;
  --to-region) TO_REGION="$2"; shift;shift;;
  --images) IMAGES="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1";;
esac; done

if [[ ! $FROM_PROFILE || ! $TO_PROFILE ]]
then
  usage "expected --from-profile and --to-profile"
fi

FROM_ACCOUNT=$(aws --profile $FROM_PROFILE sts get-caller-identity --output text --query 'Account')
TO_ACCOUNT=$(aws --profile $TO_PROFILE sts get-caller-identity --output text --query 'Account')

if [[ ! $IMAGES ]]
then
  IMAGES="tradle-kyc-nginx-proxy,trueface-spoof,rank-one"
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

if [[ $FROM_ACCOUNT == $TO_ACCOUNT && $FROM_REGION == $TO_REGION ]]
then
  usage "source and destination is the same! Be more specific please!"
fi

# convert to array
IFS=',' read -r -a IMAGES <<< "$IMAGES"

for name in "${IMAGES[@]}"
do
  copy_image "$name"
done
