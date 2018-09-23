# Cloudformation Stack for KYC services in ECS

currently supported services:

- TrueFace Spoof
- RankOne

## Usage

1. copy `scripts/env-sample.sh` to `scripts/env.sh`, and set the variables there in a way that makes sense for your deployment
1. adjust `cloudformation/stack-parameters.json`
- `S3PathToWriteDiscovery` parameter should look like this: `tdl-yourmycloudname-ltd-private-conf-bucket-xxxxx/ecs-services.json`
- set `EnableTruefaceSpoof` to `"true"` or `"false"` depending on whether you want to run a TrueFace Spoof container
- set `EnableRankOne` to `"true"` or `"false"` depending on whether you want to run a RankOne container
1. run `scripts/create-or-update-stack.sh`
