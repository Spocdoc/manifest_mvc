#!/usr/bin/env coffee --nodejs --debug-brk

fs = require 'fs'
path = require 'path'
bundle = require 'bundle-fork'
manifestMVC = require 'manifest_mvc'
async = require 'async'

mvcPath = path.resolve __dirname, '../../app/mvc'

debugger

manifestMVC mvcPath, (err, manifest) ->
  if err
    console.error "ERROR"
    console.error err.stack
  else
    console.log "got ",manifest
