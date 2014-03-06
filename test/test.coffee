#!/usr/bin/env coffee
#--nodejs --debug-brk

fs = require 'fs'
path = require 'path'
manifestMVC = require 'manifest_mvc'
async = require 'async'
beautify = require 'js-beautify'

mvcPath = path.resolve __dirname, '../../app_placeholder/mvc'

debugger

a = manifestMVC mvcPath
a.update (err) ->
  return console.error err if err?
  process.stdout.write JSON.stringify a
