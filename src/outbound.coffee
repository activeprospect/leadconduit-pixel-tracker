querystring = require('querystring')
validUrl = require('valid-url')
request = require('request')

requestParams = (vars) ->  
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


#
# Request Variables -------------------------------------------------------
#     

requestVariables = ->
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
# Handle Function ------------------------------------------------------
#

handle = (vars, callback) ->
  request requestParams(vars), (err, res) ->
    handleResponse err, res, (error, response) ->
      if error
        callback error
      else
        callback null, response


handleResponse =  (err, res, callback) ->
  event = {} 
  if err
    event.outcome = 'error'
    event.reason = err.message
  else
    if res.statusCode >= 200 and res.statusCode <= 299
      event.outcome = 'success'
    else
      event.outcome = 'failure'
      event.reason = "invalid status: (#{res.statusCode})"

  callback null, outbound: event


#
# Response Variables -------------------------------------------------------
#  
responseVariables = ->
  [
    { name: 'outbound.outcome', type: 'string', description: 'Success if outcome is in 200 range. Failure if not.' }
    { name: 'outbound.reason', type: 'string', description: 'This is returned when outcome is not success.' } 
  ]


#
# Exports ----------------------------------------------------------------
#

module.exports =
  validate: validate
  requestVariables: requestVariables
  responseVariables: responseVariables
  handle: handle
  requestParams: requestParams
  handleResponse: handleResponse




