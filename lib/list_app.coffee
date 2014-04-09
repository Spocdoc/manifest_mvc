fs = require 'fs'
path = require 'path'
_ = require 'lodash-fork'

regexTemplate = /^template\.[a-z]+$/i
regexStyle = /^style\.[a-z]+$/i

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

module.exports = listApp = (manifest, root, nameArr, className) ->

  files = fs.readdirSync root

  hasTemplate = files.some (file) -> regexTemplate.test file
  hasStyle = files.some (file) -> regexStyle.test file

  for file in files

    fullPath = "#{root}/#{file}"
    stat = fs.statSync(fullPath)

    if stat.isDirectory()
      switch file
        when 'models'
          listApp manifest, fullPath, nameArr, 'model'
        when 'views'
          listApp manifest, fullPath, nameArr, 'view'
        # when 'mixins'
        #   listApp manifest, fullPath, nameArr, 'mixin'
        when 'controllers'
          listApp manifest, fullPath, nameArr, 'controller'
        when 'styles','templates', '+'
          listApp manifest, fullPath, nameArr
        else
          if file in ['_']
            listApp manifest, fullPath, nameArr, className
          else
            nameArr.push file
            listApp manifest, fullPath, nameArr, className
            nameArr.pop()
      continue

    extname = path.extname(file)
    base = path.basename(file, extname)
    ext = extname.substr(1)
    type = nameArr.join('/')
    relPath = path.relative manifest.private.root, fullPath

    continue unless base[0] isnt '.'

    if manifest.isTemplate(file) and ((!hasTemplate and className) or regexTemplate.test file)
      # don't include the layout
      continue if _.sameFileSync(fullPath, "#{manifest.private.root}/#{manifest.layout}")

      type = formType type, base, 'template'
      manifest.templates[type] = relPath

    else if manifest.isStyle(file) and ((!hasStyle and className) or regexStyle.test file)
      type = formStyleType type, base, 'style'
      manifest.styles[type] = relPath

    else if className
      type = formType type, base, 'index'
      manifest["#{className}s"][type] = relPath

    else if base in ['model','view','controller','mixin']
      manifest["#{base}s"][type] = relPath

  return
