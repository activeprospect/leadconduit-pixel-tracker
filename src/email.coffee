querystring = require('querystring')
validUrl = require('valid-url');

#
# Request Function -------------------------------------------------------
#

request = (vars) ->
  
  id = 
    transaction_id: vars.lead.transaction_id

  url = "#{vars.lead.url}?" + querystring.encode(id)
  
  try
    req = 
      method: 'GET'
      url: url
      headers:
        'Accept': 'application/json'
        'Content-Type': 'application/x-www-form-urlencoded'

request.variables = ->
  [
    { name: 'lead.url', type: 'string', required: true, description: 'url address for tracking' }
    { name: 'lead.transaction_id', type: 'string', required: true, description: 'transaction id' }
  ]

#
# Validate Function ------------------------------------------------------
#

validate = (vars) ->
  return 'url must not be blank' unless vars.lead.url 
  return 'url must be valid' if validUrl.isUri(vars.lead.url) is undefined
  return 'transaction_id must not be blank' unless vars.lead.transaction_id

#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  event = {} 
  if res.status == 200
    parsedBody = JSON.parse(res.body)
    emailsData = parsedBody.emails?[0]
    emailResult = emailsData?.result.toLowerCase()
    webbulaError = parsedBody.errors?[0]
    if webbulaError?
      event.outcome = 'failure'
      event.reason = webbulaError
    else
      event.original = emailsData?.corrected or emailsData?.email
      event.corrected = emailsData?.email
      if badEmail(emailResult)
        event.outcome = 'failure'
        event.reason = 'email address risk level too high'
        event.threat = emailResult
      else
       event.outcome = 'success'
       event.threat = 'none'
  else
    event = { outcome: 'error', reason: "Webbula error (#{res.status})" }

  email: event

response.variables = ->
  [
    { name: 'email.threat', type: 'string', description: 'The webbula determined threat category. Reputation, Fraud, Delivery, Conversion, Beta, Invalid, Unknown, clean'}
    { name: 'email.corrected', type: 'string', description: 'The corrected email from Webbula. Will be the same as original, if no correction is made.'}
    { name: 'email.original', type: 'string', description: 'The original email, as sent, prior to getting corrected.'}
    { name: 'email.outcome', type: 'string', description: 'Was the email successfully filtered? Success or failure.' }
    { name: 'email.reason', type: 'string', description: 'If the email verification failed or if information was not appended, this is the error reason.' } 
  ]

#
# Helpers ----------------------------------------------------------------
#

badEmail = (value) ->
  return null unless value? 
  value = value.toLowerCase()
  if value == 'clean' or value == 'unknown' or value == 'valid'
   return false
  else return true

#
# Exports ----------------------------------------------------------------
#

module.exports =
  name: 'Email Data Append'
  validate: validate
  request: request
  response: response




