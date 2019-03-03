const path = require('path')
const nodeModules = path.resolve(__dirname, 'node_modules')

exports.resolver = {
  extraNodeModules: {
    react: nodeModules,
  }
}
