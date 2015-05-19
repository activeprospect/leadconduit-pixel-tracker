assert = require('chai').assert
fields = require('leadconduit-fields')
integration = require('../src/email')

describe 'Outbound Request', ->

  beforeEach ->
    @vars = lead: {url: 'http://example.com/trackingpage', transaction_id: '123456'}
    @request = integration.request(@vars)

  it 'should have url with encoded transaction_id', ->
    assert.equal @request.url, 'http://example.com/trackingpage?transaction_id=123456'

  it 'should be GET', ->
    assert.equal @request.method, 'GET'

  it 'should accept JSON', ->
    assert.equal @request.headers.Accept, 'application/json'

  it 'should have Content-Type', ->
    assert.equal @request.headers['Content-Type'], 'application/x-www-form-urlencoded' 

describe 'Outbound validate', ->

  it 'should not allow null url', ->
    error = integration.validate(lead: { url: null })
    assert.equal error, 'url must not be blank'

  it 'should not allow undefined url', ->
    error = integration.validate(lead: {url: undefined })
    assert.equal error, 'url must not be blank'

  it 'should not allow invalid url', ->
    error = integration.validate(lead: fields.buildLeadVars(url: 'nooneenoo'))
    assert.equal error, 'url must be valid'

  it 'should not error when url is valid', ->
    error = integration.validate(lead: fields.buildLeadVars(url: 'https://www.npmjs.com', transaction_id:'1111a'))
    assert.equal error, undefined

  it 'should not allow null transaction_id', ->
    error = integration.validate(lead: { url: 'https://www.npmjs.com', transaction_id: null })
    assert.equal error, 'transaction_id must not be blank'

  it 'should not allow undefined transaction_id', ->
    error = integration.validate(lead: { url: 'https://www.npmjs.com', transaction_id: undefined })
    assert.equal error, 'transaction_id must not be blank'

describe 'Success Response', ->
  it 'should set a success outcome for a good email', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"foo@bar.com","result":"clean"}]
            }
            """
    expected =
      email: 
        "outcome": "success"
        "original": "foo@bar.com"
        "corrected": "foo@bar.com"
        "threat": "none"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'should parse original email with corrected email when corrected is present', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"foo@bar.com","result":"clean", "corrected":"foo@bar.co"}]
            }
            """
    expected =
      email: 
        "outcome": "success"
        "original": "foo@bar.co"
        "corrected": "foo@bar.com"
        "threat": "none"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'should parse original email and corrected email when corrected is not present', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"foo@bar.com","result":"clean"}]
            }
            """
    expected =
      email: 
        "outcome": "success"
        "original": "foo@bar.com"
        "corrected": "foo@bar.com"
        "threat": "none"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'should set outcome for a bad email', ->
    res =
      status: 200,
      body: """
            {
            "success": true,
            "emails":[{"email":"foo@bar.com","result":"clean","corrected":"foo@bar.co"}]
            }
            """
    expected =
      email:
        outcome: "success"
        corrected: "foo@bar.com"
        original: "foo@bar.co"
        threat: "none"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

describe 'Failure Response', ->

  it 'Email should be corrected even when result implies risk', ->
    res =
      status: 200,
      body: """
          {
          "success":true,
          "emails":[{"email":"hugotwoa@aol.com","result":"Reputation","corrected":"hugotwoa@aol.co"}]
          }
          """
    expected =
      email:
        outcome: "failure"
        original: "hugotwoa@aol.co"
        corrected: "hugotwoa@aol.com"
        threat: "reputation"
        reason: "email address risk level too high"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response
  

  it 'outcome should be failure when result is Reputation', ->
    res =
      status: 200,
      body: """
            {
            "success": true,
            "emails":[{"email":"hugotwoa@aol.com","result":"Reputation"}]
            }
            """
    expected =
      email:
        outcome: "failure"
        original: "hugotwoa@aol.com"
        corrected: "hugotwoa@aol.com"
        threat: "reputation"
        reason: "email address risk level too high"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'outcome should be failure when result is Delivery', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"alkjldj", "result":"Delivery"}]
            }
            """
    expected =
      email:
        outcome: "failure"
        original: "alkjldj"
        corrected: "alkjldj"
        threat: "delivery"
        reason: "email address risk level too high"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'outcome should be failure when result is Fraud', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"804030@LIVE.COM","result":"Fraud"}]
            }
            """
    expected =
      email:
        outcome: "failure"
        original: "804030@LIVE.COM"
        corrected: "804030@LIVE.COM"
        threat: "fraud"
        reason: "email address risk level too high"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'outcome should be failure when result is Conversion', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"dougeth@aol.com","result":"Conversion"}]
            }
            """
    expected =
      email:
        outcome: "failure"
        original: "dougeth@aol.com"
        corrected: "dougeth@aol.com"
        threat: "conversion"
        reason: "email address risk level too high"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'outcome should be failure when result is Invalid', ->
    res =
      status: 200,
      body: """
            {
            "success":true,
            "emails":[{"email":"dougeth@juno.com","result":"Invalid"}]
            }
            """
    expected =
      email:
        outcome: "failure"
        original: "dougeth@juno.com"
        corrected: "dougeth@juno.com"
        threat: "invalid"
        reason: "email address risk level too high"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  

describe 'Error Response', ->
  it 'should parse error reason when success is true', ->
    res =
      status: 200,
      body: """
            {
              "success": true,
              "errors": ["10501 : Emails parameter is blank"]
            } 
            """
    expected =
      email:
        outcome: "failure"
        reason: "10501 : Emails parameter is blank"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'should parse error reason when success is false', ->
    res =
      status: 200,
      headers:
        'Content-Type': 'application/json'
      body: """
            {
              "success": false,
              "errors": ["10111 : Invalid API Key"]
            }
            """
    expected =
      email:
        outcome: "failure"
        reason: "10111 : Invalid API Key"
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response
  
  it 'should return error outcome on non-200 response status', ->
    res =
      status: 400,
      headers:
        'Content-Type': 'application/json'
      body: """
            {
              "outcome": "error",
              "reason": "Webbula error (400)"
            }
            """
    expected =
      email:
        outcome: 'error'
        reason: 'Webbula error (400)'
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response
