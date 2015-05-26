querystring = require('querystring')
validUrl = require('valid-url');

#
# Request Function -------------------------------------------------------
#

request = (vars) ->
  
  url = vars.lead.url
  
  req = 
    method: 'GET'
    url: url
    headers:
      'Accept': 'application/json'
      'Content-Type': 'application/x-www-form-urlencoded'

request.variables = ->
  [
    { name: 'lead.url', type: 'string', required: true, description: 'url address for tracking' }
  ]

#
# Validate Function ------------------------------------------------------
#

validate = (vars) ->
  return 'url must not be blank' unless vars.lead.url 
  return 'url must be valid' if validUrl.isUri(vars.lead.url) is undefined

#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  outbound = {} 
  if 300 - res.status >= 0
    outbound.outcome = 'success'
    outbound.reason = "valid status: (#{res.status})"
  else
    outbound.outcome = 'failure' 
    outbound.reason = "invalid status: (#{res.status})"

  outbound

response.variables = ->
  [
    { name: 'email.outcome', type: 'string', description: 'Success if outcome is in 200 range. Failure if not.' }
    { name: 'email.reason', type: 'string', description: 'The status code returned after sending a GET request.' } 
  ]

#
# Exports ----------------------------------------------------------------
#

module.exports =
  name: 'Outbound Data Append'
  validate: validate
  request: request
  response: response




