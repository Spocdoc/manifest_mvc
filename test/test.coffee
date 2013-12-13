#!/usr/bin/env coffee#--nodejs --debug-brk

fs = require 'fs'
path = require 'path'
manifestMVC = require 'manifest_mvc'
async = require 'async'

mvcPath = path.resolve __dirname, '../../app/mvc'

debugger

a = manifestMVC mvcPath
a.update (err) ->
  return console.error err if err?

# console.log a.clientHtml()
