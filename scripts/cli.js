#!/usr/bin/env node

const { promisify } = require('util')
const fs = require('fs')
const path = require('path')
const AWS = require('aws-sdk')
const yargs = require('yargs')
const cloneDeep = require('lodash/cloneDeep')
const Promise = require('bluebird')
const YAML = require('js-yaml')
// const schema = require('cloudformation-js-yaml-schema').genSchema(YAML)
const log = (...args) => console.log(...args)
const paths = {
  ecs: path.resolve(__dirname, '../cloudformation/ecs.yml'),
  bastion: path.resolve(__dirname, '../cloudformation/bastion.yml'),
}

const _readFile = promisify(fs.readFile.bind(fs))
const _writeFile = promisify(fs.writeFile.bind(fs))
const readFile = filePath => _readFile(filePath, { encoding: 'utf8' })
const writeFile = (filePath, value) => _writeFile(filePath, value, { encoding: 'utf8' })
const regions = [
  'us-east-2',
  'us-east-1',
  'us-west-2',
  'us-west-1',
  'eu-west-3',
  'eu-west-2',
  'eu-west-1',
  'eu-central-1',
  'ap-northeast-2',
  'ap-northeast-1',
  'ap-southeast-2',
  'ap-southeast-1',
  'ca-central-1',
  'ap-south-1',
  'sa-east-1',
  // 'us-gov-west-1',
]

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
  let { AWS } = policy.Statement[0].Principal
  if (typeof AWS === 'string') {
    AWS = [AWS]
  }

  if (!AWS.includes(iamArn)) {
    AWS.push(iamArn)
  }
}

const getIamArnForAccount = account => `arn:aws:iam::${account}:root`

const byCreationDateDesc = (a, b) => new Date(b.CreationDate) - new Date(a.CreationDate)

const getLatestECSImage = async ({ region }) => {
  const ec2 = getEC2ClientByRegion(region)
  const { Images } = await ec2.describeImages({
    Filters: [
      {
        Name: 'owner-alias',
        Values: [
          'amazon',
        ]
      },
      {
        Name: 'name',
        Values: [
          '*ecs-optimized*',
        ]
      },
      {
        Name: 'state',
        Values: [
          'available'
        ]
      }
    ]
  }).promise()

  const latest = Images.sort(byCreationDateDesc)[0]
  return latest
}

const getEC2ClientByRegion = region => {
  AWS.config.update({ region })
  return new AWS.EC2()
}

const updateAMIs = async () => {
  let latestAMIs = await Promise.mapSeries(regions, region => getLatestECSImage({ region }))
  latestAMIs = latestAMIs
    .filter(ami => ami)
    .map(ami => ami.ImageId)

  const byRegion = latestAMIs.reduce((map, AMI, i) => {
    map[regions[i]] = { AMI }
    return map
  }, {})

  const amisYml = YAML.safeDump({
    AWSRegionToAMI: byRegion
  })
  .split('\n')
  .map(line => '  ' + line)
  .join('\n')

  await Promise.map([paths.ecs, paths.bastion], async filePath => {
    const yml = await readFile(filePath)
    const start = yml.indexOf('\n# START_AMIS')
    const end = yml.indexOf('# END_AMIS')
    const before = yml.slice(0, start)
    const middle = amisYml
    const after = yml.slice(end)
    await writeFile(filePath, [
      before,
      '# START_AMIS',
      middle,
      after
    ].join('\n'))
  })
}

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
  .command({
    command: 'update-amis',
    desc: 'update amis in template',
    handler: ({ region }) => {
      AWS.config.update({ region })
      return updateAMIs()
    },
    builder: {
      region: {
        default: 'us-east-1',
      },
    }
  })
  // .help()
  .argv
