path = require 'path'
async = require 'async'
typeToClass = require './type_to_class'
nib = require 'nib'
fileMemoize = require 'file_memoize'

# note: in principle this could be modularized so each style type is in a
# separate file that's `require`'d as needed

styleLoaders =
  'styl': do ->
    wrapInClass = (styl, type) ->
      if type
        lines = []
        lines.push ".#{type}"
        lines.push "  #{line}" for line in styl.split '\n'
        lines.join '\n'
      else
        styl

    stylus = require 'stylus'

    (fullPath, type, content, cb) ->
      type = typeToClass type

      async.waterfall [
        (next) -> stylus(content).set('filename',fullPath).set('linenos',true).use(nib()).import('nib').render next
        (css, next) ->
          css = wrapInClass(css,type)

          async.parallel
            debug: (done) -> stylus.render css, done
            release: (done) -> stylus.render css, compress: true, done
            next
      ], cb

module.exports =
  handles: (ext) -> styleLoaders[ext]?

  compile: fileMemoize (fullPath, type, content, cb) ->
    ext = path.extname(fullPath)[1..]
    styleLoaders[ext](fullPath, type, content, cb)

