
const AWS = require('aws-sdk')
AWS.config.update({
  region: 'us-east-1',
})

AWS.config.credentials = new AWS.SharedIniFileCredentials({
  profile: 'mv',
})

const { handler } = require('./service/functions/update-dns')
const dns = require('./service/dns')(new AWS.Route53())
const ec = require('./service/ec')({
  ecs: new AWS.ECS(),
  ec2: new AWS.EC2(),
})

const ctx = {
  hostedZone: 'Z21K538UFSFAK',
  cluster: 'MainnetParity2',
  dnsName: 'ethmainnet2.mvayngrib.com',
}

const run = async op => {
  const [ip] = await ec.getEC2PrivateIps(ctx)
  if (op.toLowerCase() === 'delete') {
    await dns.deleteARecord({ ...ctx, ip })
  } else {
    await dns.upsertARecord({ ...ctx, ip })
  }
}

const create = () => run('Create')
const del = () => run('Delete')
const op = del

op().catch(console.error)
