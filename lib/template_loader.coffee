path = require 'path'
fileMemoize = require 'file_memoize'

templateLoaders =
  'html': (str, cb) -> cb null, str
  'htm': (str, cb) -> cb null, str
  'jade': (str, cb) ->
    cb null, require('jade').compile(str)()

module.exports =
  handles: (ext) ->
    templateLoaders[ext]?

  compile: fileMemoize (fullPath, type, content, cb) ->
    ext = path.extname(fullPath)[1..]
    templateLoaders[ext](content, cb)

