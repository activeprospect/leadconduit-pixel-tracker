assert = require('chai').assert
fields = require('leadconduit-fields')
integration = require('../src/outbound')

describe 'Outbound Request', ->

  beforeEach ->
    @vars = lead: {url: 'http://example.com/trackingpage'}
    @request = integration.request(@vars)

  it 'should have a valid URL', ->
    assert.equal @request.url, 'http://example.com/trackingpage'

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

describe 'Success Response', ->
  
  it 'should parse success when status is in the 200 range', ->
    res =
      status: 200,
    expected =
          outcome: 'success'
          reason: 'valid status: (200)'

    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

describe 'Failure Response', ->

  it 'should parse failure when status is not in 200 range', ->
    res =
      status: 403,
    expected =
          outcome: 'failure'
          reason: 'invalid status: (403)'

    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  

