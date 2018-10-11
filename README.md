# Cloudformation Stack for KYC services in ECS

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Currently Supported Services:](#currently-supported-services)
- [Overview](#overview)
- [Usage](#usage)
- [Scripts](#scripts)
  - [scripts/build-and-upload.sh](#scriptsbuild-and-uploadsh)
  - [scripts/validate-templates.sh](#scriptsvalidate-templatessh)
  - [scripts/upload-assets.sh](#scriptsupload-assetssh)
  - [scripts/create-or-update-stack.sh](#scriptscreate-or-update-stacksh)
  - [scripts/delete-and-create-stack.sh](#scriptsdelete-and-create-stacksh)
  - [scripts/get-container-instance.sh](#scriptsget-container-instancesh)
  - [scripts/get-container-instance-ip.sh](#scriptsget-container-instance-ipsh)
  - [scripts/get-api-url.sh](#scriptsget-api-urlsh)
  - [scripts/restart-task.sh](#scriptsrestart-tasksh)
  - [scripts/reboot-container-instance.sh](#scriptsreboot-container-instancesh)
  - [scripts/cli.js](#scriptsclijs)
    - [update-amis](#update-amis)
    - [add-pull-access](#add-pull-access)
- [Development](#development)
  - [Prerequisites](#prerequisites)
  - [Adding a Service](#adding-a-service)
- [Todo](#todo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Currently Supported Services:

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

## Scripts

The following scripts make use of the environment variables exported from `scripts/env.sh`, so make sure you set those correctly first. 

*Note: the ones pertaining to container instances currently assume a single container instance is running.*

### scripts/build-and-upload.sh

build and upload an image from one of the dockerfiles in the `docker/` directory

Usage: `./scripts/build-and-upload.sh [repository-name] [path/to/dir/with/Dockerfile]`
Example: `./scripts/build-and-upload.sh trueface-spoof docker/trueface-spoof`

### scripts/validate-templates.sh

validate cloudformation templates in the `cloudformation/` directory

### scripts/upload-assets.sh

uploads cloudformation templates and any related assets to S3

### scripts/create-or-update-stack.sh

- validates templates
- uploads templates to s3
- creates or updates your cloudformation stack

### scripts/delete-and-create-stack.sh

you guessed it

### scripts/get-container-instance.sh

get the instance id of the currently running container instance

### scripts/get-container-instance-ip.sh

get the private IP of the currently running container instance

### scripts/get-api-url.sh

get the base url of the load balancer, i.e. its dns name

### scripts/restart-task.sh

force a task to restart, useful when you pushed a new image and want the running container instance to deploy it

### scripts/reboot-container-instance.sh

force the currently running container instance to reboot

### scripts/cli.js

#### update-amis

updates the AMIs in the templates to the latest ecs-optimized AMIs published by Amazon

Example: `./scripts/cli.js update-amis`

#### add-pull-access

give another AWS account pull access to repos

Example: `./scripts/cli.js add-pull-access --region us-east-1 --account 1234567 --repos trueface-spoof,rank-one,tradle-kyc-nginx-proxy`

## Development

### Prerequisites

- [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
- [jq](https://stedolan.github.io/jq/download/): a great command line JSON parser (On OS X, you can `brew install jq`)

### Adding a Service

Let's say you want to add a third party service that checks if the user is a zombie registered with the Zombie Census Bureau.

1. create a directory under `./docker` with your service's Dockerfile, e.g. `./docker/zombie-registry`
2. run `./scripts/build-and-upload.sh zombie-registry zombie-registry` (see #scripts for usage)
3. search for `RankOne` and `RANK_ONE` in `cloudformation/*.yml` and add similar stack variables and container environment variables for your service
4. add a block in `docker/nginx/entrypoint.sh` which takes the environment variables passed to the container via cloudformation, and builds the location template for your service

## Todo

[Good video on ECS](https://www.youtube.com/watch?v=ncN47QMt7nw)

Figure out the two scaling methods (watch [this](https://youtu.be/ncN47QMt7nw?t=1279) part of the video linked above): 
- service autoscaling: changing # of containers running to meet load. Scaling is based on USAGE, not reservation. CPU usage triggers can come via cloudwatch alarms.
- cluster autoscaling: changing # of instances to make room for deploying more containers (and removing that room when it's no longer needed). Scaling is based on CPU & memory RESERVATION.
