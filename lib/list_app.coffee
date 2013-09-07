fs = require 'fs'
path = require 'path'
templateLoader = require './template_loader'
styleLoader = require './style_loader'
async = require 'async'
require 'debug-fork'
debug = global.debug 'ace:boot:app'
_ = require 'lodash-fork'

getInode = async.memoize (filePath, cb) ->
  fs.stat filePath, (err, stat) ->
    return cb(err) if err?
    cb null, ""+stat.ino

formType = (type, base, stub) ->
  unless base is stub
    type += '/' if type
    type += "#{base}"
  type

formStyleType = (type, base, stub) ->
  unless base is stub
    type += '/' if type
    type += "#{base}"
  type

listApp = (ret, arr, root, pending, done, className) ->
  for file in fs.readdirSync root
    fullPath = "#{root}/#{file}"
    stat = fs.statSync(fullPath)

    if stat.isDirectory()
      switch file
        when 'models'
          listApp ret, arr, fullPath, pending, done, 'model'
        when 'views'
          listApp ret, arr, fullPath, pending, done, 'view'
        when 'controllers'
          listApp ret, arr, fullPath, pending, done, 'controller'
        when 'styles','templates', '+'
          listApp ret, arr, fullPath, pending, done
        else
          if file in ['_']
            listApp ret, arr, fullPath, pending, done, className
          else
            arr.push file
            listApp ret, arr, fullPath, pending, done, className
            arr.pop()

      continue

    extname = path.extname(file)
    base = path.basename(file, extname)
    ext = extname[1..]
    type = arr.join('/')

    continue unless base[0] isnt '.'

    if templateLoader.handles ext
      type = formType type, base, 'template'
      debug "loaded template\t\t #{type}"

      pending()
      do (fullPath, type) ->
        async.waterfall [
          (next) -> fs.readFile fullPath, 'utf-8', next
          (content, next) -> templateLoader.compile fullPath, type, content, next
          (parsed, next) ->
            ret['template'][type] = parsed
            ret['files']['template'][type] = fullPath
            next()
        ], done

    else if styleLoader.handles ext
      type = formStyleType type, base, 'style'
      debug "loaded style\t\t #{type}"

      pending()
      do (fullPath, type) ->
        async.waterfall [
          (next) -> fs.readFile fullPath, 'utf-8', next
          (content, next) -> styleLoader.compile fullPath, type, content, next
          (parsed, next) ->
            ret['style'][type] = parsed
            ret['files']['style'][type] = fullPath
            next()
        ], done

    else if className
      type = formType type, base, 'index'
      debug "loaded #{className}\t\t #{type}"
      ret[className][type] = fullPath

    else if base in ['model','view','controller']
      debug "loaded #{base}\t\t #{type}"
      ret[base][type] = fullPath

module.exports = (root, cb) ->
  root = path.resolve root

  ret = reload: (done) -> run done

  run = (cb) ->
    ret[type] = {} for type in ['model','view','controller','template','style']
    ret.routes = "#{root}/routes"
    ret.mediator = "#{root}/mediator"
    ret.files =
      template: {}
      style: {}

    try
      ret.index = require.resolve "#{root}"
    catch _error

    count = 0
    done = (err) ->
      return cb(err) if err?
      unless --count
        cb null, ret
    pending = -> ++count

    pending()
    listApp ret, [], root, pending, done
    done()

    return

  run cb
