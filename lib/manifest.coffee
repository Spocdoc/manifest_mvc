fs = require 'fs'
path = require 'path'
_ = require 'lodash-fork'
require 'debug-fork'
debug = global.debug 'manifest'
glob = require 'glob'
listApp = require './list_app'
beautify = require 'js-beautify'
callsite = require 'callsite'
temp = require 'temp'

temp.track()

DEFAULT_BUNDLER = 'bundle-fork'
DEFAULT_FRAMEWORK = 'ace_mvc'
DEFAULT_ASSET_ROOT = '../public'

class PrivateData
  toJSON: ->

module.exports = class Manifest
  constructor: (filePath) ->
    # resolve relative to caller's file unless absolute
    unless filePath.charAt(0) in ['/','\\']
      stack = callsite()
      filePath = path.resolve path.dirname(stack[1].getFileName()), filePath

    filePath += "/manifest.json" if fs.statSync(filePath).isDirectory()

    inst = JSON.parse fs.readFileSync(filePath, encoding:'utf8')
    inst.__proto__ = Manifest.prototype # hard coded "Manifest" to allow without operator new
    inst.options ||= {}

    p = inst.private = new PrivateData
    p.filePath = filePath
    p.root = path.dirname path.resolve filePath
    p.bundlerPath = inst.options.bundler || DEFAULT_BUNDLER
    p.bundler = require p.bundlerPath
    p.frameworkPath = inst.options.framework || DEFAULT_FRAMEWORK
    p.framework = require p.frameworkPath
    p.assetRoot = path.resolve p.root, (inst.options.assetRoot || DEFAULT_ASSET_ROOT)

    return inst

  isTemplate: (filePath) -> @private.framework.isTemplate filePath
  isStyle: (filePath) -> @private.bundler.isStyle filePath

  update: (done) ->
    {root, framework, bundler, filePath} = @private

    @routes = "routes"
    @mediator = "mediator"

    try
      require.resolve root
      @index = "index"
    catch _error
      delete @index

    for file in (glob.sync 'layout.*', cwd: root) when framework.isTemplate file
      @layout = "#{file}"
      break

    @templates = {}
    @styles = {}
    @models = {}
    @views = {}
    @controllers = {}

    listApp this, root, [], ''

    debug "manifest before bundle:", this

    bundler this, (err) =>
      if err?
        console.error err
        console.error err?.stack
        return

      # fs.writeFile filePath, beautify(JSON.stringify(this), wrap_line_length: 70), done
      temp.open 'manifest', (err, info) =>
        return done err if err?
        fs.write info.fd, beautify(JSON.stringify(this), wrap_line_length: 70)
        fs.close info.fd, (err) =>
          return done err if err?
          fs.rename info.path, filePath, (err) =>
            return done err if err?
            temp.cleanup()
            done()


  clientHtml: -> @private.bundler.clientHtml this

