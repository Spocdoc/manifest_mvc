charsRegex = /[^A-Za-z0-9-_]/g
startRegex = /^[^A-Za-z]+/

module.exports = (type) ->
  type.replace('/', '-')
    .replace(' ', '_')
    .replace(charsRegex,'')
    .replace(startRegex,'')

