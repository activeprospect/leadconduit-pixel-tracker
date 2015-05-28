querystring = require('querystring')
validUrl = require('valid-url');

#
# Request Function -------------------------------------------------------
#

request = (vars) ->
  
  req = 
    method: 'GET'
    url: vars.url
    headers:
      'Accept': '*/*'
      'Content-Type': 'application/x-www-form-urlencoded'

request.variables = ->
  [
    { name: 'url', type: 'string', required: true, description: 'url address for tracking' }
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
  outbound = {} 
  if res.status >= 200 and res.status <= 299
    outbound.outcome = 'success'
  else
    outbound.outcome = 'failure' 
    outbound.reason = "invalid status: (#{res.status})"

  outbound

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




