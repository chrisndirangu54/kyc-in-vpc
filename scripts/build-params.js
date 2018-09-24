const fs = require('fs')
const path = require('path')
let [paramsFile, templateDir] = process.argv.slice(2)
if (!paramsFile) {
  throw new Error(`expected base params file as first arg`)
}

paramsFile = path.resolve(__dirname, paramsFile)
if (!fs.existsSync(paramsFile)) {
  throw new Error(`file does not exist: ${paramsFile}`)
}

const log = (...args) => console.log(...args)
const prettify = obj => JSON.stringify(obj, null, 2)
const prettyPrint = obj => log(prettify(obj))

const loadEnv = () => fs.readFileSync(path.join(__dirname, 'env.sh'), { encoding: 'utf-8' })
  .split('\n')
  .map(s => s.replace(/^export\s+/, '').trim().split('='))
  .reduce((map, [k, v]) => {
    map[k] = v
    return map
  }, {})

const splitOnIdx = (str, idx) => ([str.slice(0, idx), str.slice(idx)])

const build = async paramsFile => {
  const params = require(paramsFile).slice()
  const getParam = key => params.find(p => p.ParameterKey === key)
  const tDir = getParam('S3TemplatesBaseUrl')
  if (!tDir) {
    const [bucket, path] = splitOnIdx(templateDir, templateDir.indexOf('/'))
    debugger
    params.push({
      ParameterKey: 'S3TemplatesBaseUrl',
      // trim begin/end slashes
      ParameterValue: `https://${bucket}.s3.amazonaws.com/${path.slice(1)}`
    })
  }

  return params
}

build(paramsFile).then(prettyPrint, console.error)
