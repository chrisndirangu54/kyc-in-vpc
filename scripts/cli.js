#!/usr/bin/env node

const AWS = require('aws-sdk')
const yargs = require('yargs')
const cloneDeep = require('lodash/cloneDeep')

const BASE_POLICY = {
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": []
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}

const addPullAccess = ({ policy, iamArn }) => {
  const { AWS } = policy.Statement[0].Principal
  if (!AWS.includes(iamArn)) {
    AWS.push(iamArn)
  }
}

const getIamArnForAccount = account => `arn:aws:iam::${account}:root`

class ECRWrapper {
  constructor(client) {
    this.client = client
  }

  async addPullAccess({ account, repos }) {
    if (!account) {
      throw new Error('expected AWS account ID "account"')
    }

    if (!(repos && repos.length)) {
      throw new Error('expected repos comma-delimited list')
    }

    const { repositories } = await this.client.describeRepositories({ repositoryNames: repos }).promise()
    const arns = repositories.map(r => r.repositoryArn)
    await Promise.all(repos.map((repo, i) => {
      return this.addPullAccessToRepo({ account, repo, repoArn: arns[i] })
    }))
  }

  async addPullAccessToRepo({ account, repo, repoArn }) {
    const iamArn = getIamArnForAccount(account)
    let policy
    try {
      const { policyText } = await this.client.getRepositoryPolicy({ repositoryName: repo }).promise()
      policy = JSON.parse(policyText)
    } catch (err) {
      if (err.name.startsWith('AccessDenied')) {
        throw new Error(`access denied: ${repo}`)
      }

      if (err.name !== 'RepositoryPolicyNotFoundException') {
        throw err
      }
    }

    if (!policy) {
      policy = cloneDeep(BASE_POLICY)
    }

    addPullAccess({
      policy,
      repoArn,
      iamArn,
    })

    await this.client.setRepositoryPolicy({
      repositoryName: repo,
      policyText: JSON.stringify(policy),
    }).promise()

    log(`gave account ${account} pull access to repository: ${repoArn}`)
  }
}

yargs
  .command({
    command: 'add-pull-access [options]',
    desc: 'add pull access to a ECR repos',
    handler: ({ region, ...opts }) => {
      // weird to update global
      // but it's only one command at a time so i guess it's ok...

      AWS.config.update({ region })
      return new ECRWrapper(new AWS.ECR()).addPullAccess(opts)
    },
    builder: {
      region: {
        default: 'us-east-1',
      },
      repos: {
        default: ['trueface-spoof', 'rank-one', 'tradle-kyc-nginx-proxy'],
      },
      account: {
        type: 'string',
      },
    }
  })
  // .help()
  .argv
