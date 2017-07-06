querystring = require('querystring')
validUrl = require('valid-url')

#
# Request Function -------------------------------------------------------
#

request = (vars) ->
  if vars.parameter and Object.keys(vars.parameter).length > 1    
    encodedQuery = querystring.encode(vars.parameter)
    url = "#{vars.url}?#{encodedQuery}"
  else
    url = "#{vars.url}"

  req = 
    method: 'GET'
    url: url
    headers:
      'Accept': '*/*'
      'Content-Type': 'application/x-www-form-urlencoded'

request.variables = ->
  [
    { name: 'url', type: 'string', required: true, description: 'url address for tracking' }
    { name: 'parameter.*', type: 'wildcard', required: false, description: 'Additional parameter to add onto the pixel query URL' }
  ]

#
# Validate Function ------------------------------------------------------
#

validate = (vars) ->
  return 'url must not be blank' unless vars.url 
  return 'url must be valid' if validUrl.isUri(vars.url) is undefined

#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  event = {} 
  if res.status >= 200 and res.status <= 299
    event.outcome = 'success'
  else
    event.outcome = 'failure' 
    event.reason = "invalid status: (#{res.status})"

  outbound: event

response.variables = ->
  [
    { name: 'outbound.outcome', type: 'string', description: 'Success if outcome is in 200 range. Failure if not.' }
    { name: 'outbound.reason', type: 'string', description: 'This is the status code when returned code is not in 200 range.' } 
  ]

#
# Exports ----------------------------------------------------------------
#

module.exports =
  validate: validate
  request: request
  response: response




