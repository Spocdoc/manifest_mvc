path = require 'path'
async = require 'async'
typeToClass = require '../type_to_class'
nib = require 'nib'
_ = require 'lodash-fork'

# note: in principle this could be modularized so each style type is in a
# separate file that's `require`'d as needed

regexImport = /^\s*@import/
regexExtend = /^(\s*@extend)(\s*[^\s\$].*)$/
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

    (fullPath, type, content, cb) ->
      type = typeToClass type

      imports = ''
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

        if regexImport.test line
          imports += line + '\n'
        else if m = regexDollar.exec line
          inDollar = true
          dollarSpace = m[1].length
          regexDollarSpace = ///^#{m[1]}\s///
          dollars += line.substr(dollarSpace) + '\n'
        else
          content += line + '\n'
      content = imports + dollars + wrapInClass(content, type)

      async.parallel
        debug: (done) ->
          stylus(content).set('filename',fullPath).set('linenos',true).use(nib()).import('nib').render done

        release: (done) ->
          stylus(content).set('filename',fullPath).set('linenos',false).set('compress',true).use(nib()).import('nib').render done

        cb

module.exports =
  handles: (ext) -> styleLoaders[ext]?

  compile: _.fileMemoize (fullPath, type, content, cb) ->
    ext = path.extname(fullPath)[1..]
    styleLoaders[ext](fullPath, type, content, cb)

