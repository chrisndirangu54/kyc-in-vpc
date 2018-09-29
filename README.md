# Cloudformation Stack for KYC services in ECS

currently supported services:

- TrueFace Spoof
- RankOne

## Overview

This repo hosts the templates for a CloudFormation stack that deploys a number of third party KYC services in ECS.

The structure is based on this [reference architecture](https://github.com/aws-samples/ecs-refarch-cloudformation) and looks like this:

- cloudformation/main.yml: the main stack, which launches several child stacks:
  - cloudformation/vpc.yml: a stack which creates a VPC that spans 3 availability zones in a region
  - cloudformation/load-balancers.yml: surprise! The application load balancer
  - cloudformation/security-groups.yml: an SG for the load balancer, and an SG for the ECS services, which allows ingress only via the load balancer SG
  - cloudformation/ecs.yml: the meat and the veggies. The service, scaling group, container definitions, etc.
  - cloudformation/bastion.yml: optional ssh bastion host
  - cloudformation/dns.yml: optional dns alias (doesn't work yet)

This stack is somewhat flexible, in that you can use parameters to enable/disable services (e.g. see parameters EnableTruefaceSpoof, EnableRankOne).

## Usage

1. copy `scripts/env-sample.sh` to `scripts/env.sh`, and set the variables there in a way that makes sense for your deployment
1. create `cloudformation/stack-parameters.json` based on `cloudformation/stack-parameters-example.json`  
    - `S3PathToWriteDiscovery` parameter should look like this: `tdl-yourmycloudname-ltd-private-conf-bucket-xxxxx/ecs-services.json`  
    - set `EnableTruefaceSpoof` to `"true"` or `"false"` depending on whether you want to run a TrueFace Spoof container  
    - set `EnableRankOne` to `"true"` or `"false"` depending on whether you want to run a RankOne container  
1. run `scripts/create-or-update-stack.sh`

## Todo

[Good video on ECS](https://www.youtube.com/watch?v=ncN47QMt7nw)

Figure out the two scaling methods (watch [this](https://youtu.be/ncN47QMt7nw?t=1279) part of the video linked above): 
- service autoscaling: changing # of containers running to meet load. Scaling is based on USAGE, not reservation. CPU usage triggers can come via cloudwatch alarms.
- cluster autoscaling: changing # of instances to make room for deploying more containers (and removing that room when it's no longer needed). Scaling is based on CPU & memory RESERVATION.
