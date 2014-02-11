charsRegex = /[^A-Za-z0-9-_]/g
startRegex = /^[^A-Za-z]+/

module.exports = (type) ->
  type.toLowerCase()
    .replace(/\//g, '-')
    .replace(/\x20/g, '_')
    .replace(charsRegex,'')
    .replace(startRegex,'')

