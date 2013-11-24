path = require 'path'
fs = require 'fs'
async = require 'async'
typeToClass = require '../type_to_class'
nib = require 'nib'
_ = require 'lodash-fork'

# note: in principle this could be modularized so each style type is in a
# separate file that's `require`'d as needed

regexRaisedImport = /^\s*@import\s+['"](?!\.\/)/
regexReadImport = /^(\s*)@import\s+(['"])(\.\/.*?)\2.*$/gm
regexVariable = /^\s*\w+\s*=/
regexExtend = /^(\s*@extends?)(\s*[^\s\$].*)$/
regexBlank = /^\s*$/
regexDollar = /^(\s*)\$/

styleLoaders =
  'styl': do ->
    wrapInClass = (styl, type) ->
      if type
        str = ".#{type}\n"
        for line in styl.split '\n'
          if m = regexExtend.exec line
            str += "  " + m[1] + " .#{type}" + m[2] + "\n"
          else
            str += "  #{line}\n"
        str
      else
        styl

    stylus = require 'stylus'

    replaceImports = (dirPath, content) ->
      content.replace regexReadImport, (match, indentation, quot, importedPath) ->
        filePath = path.resolve(dirPath, importedPath)
        filePath += '.styl' unless path.extname filePath
        fileContent = fs.readFileSync filePath , encoding: 'utf8'
        fileContent = replaceImports dirPath, fileContent
        fileContent.replace /^/gm, indentation

    (fullPath, type, content, cb) ->
      type = typeToClass type
      dirPath = path.dirname fullPath

      content = replaceImports dirPath, content

      header = ''
      dollars = ''
      lines = content.split '\n'
      content = ''
      inDollar = false
      dollarSpace = 0
      regexDollarSpace = //

      for line in lines when not regexBlank.test line
        if inDollar
          if regexDollarSpace.test line
            dollars += line.substr(dollarSpace) + '\n'
            continue
          else
            inDollar = false

        if regexRaisedImport.test line
          header += line + '\n'
        else if m = regexReadImport.exec line
          filePath = m[2]
        else if regexVariable.test line
          header = line + '\n' + header
        else if m = regexDollar.exec line
          inDollar = true
          dollarSpace = m[1].length
          regexDollarSpace = ///^#{m[1]}\s///
          dollars += line.substr(dollarSpace) + '\n'
        else
          content += line + '\n'

      content = header + dollars + if content then wrapInClass(content, type) else ''

      async.parallel
        debug: (done) ->
          stylus(content).set('filename',fullPath).set('linenos',true).use(nib()).import('nib').render done

        release: (done) ->
          stylus(content).set('filename',fullPath).set('linenos',false).set('compress',true).use(nib()).import('nib').render done

        cb

module.exports =
  handles: (ext) -> styleLoaders[ext]?

  compile: _.fileMemoize (fullPath, type, cb) ->
    fs.readFile fullPath, encoding: 'utf-8', (err, content) ->
      return cb err if err?
      ext = path.extname(fullPath).substr(1)
      styleLoaders[ext](fullPath, type, content, cb)

