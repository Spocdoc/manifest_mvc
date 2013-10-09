path = require 'path'
_ = require 'lodash-fork'
fs = require 'fs'

templateLoaders =
  'html': (str, cb) -> cb null, str
  'htm': (str, cb) -> cb null, str
  'jade': (str, cb) ->
    cb null, require('jade').compile(str)()

module.exports =
  handles: (ext) ->
    templateLoaders[ext]?

  compile: _.fileMemoize (fullPath, type, cb) ->
    fs.readFile fullPath, encoding: 'utf-8', (err, content) ->
      return cb err if err?
      ext = path.extname(fullPath).substr(1)
      templateLoaders[ext](content, cb)

