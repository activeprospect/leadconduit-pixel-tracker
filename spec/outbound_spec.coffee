assert = require('chai').assert
integration = require('../src/outbound')
nock = require('nock')

describe 'Outbound Request', ->

  beforeEach ->
    @vars = {url: 'http://example.com/trackingpage'}

  it 'should have a valid URL', ->
    @request = integration.requestParams(@vars)
    assert.equal @request.url, 'http://example.com/trackingpage'

  it 'should be GET', ->
    @request = integration.requestParams(@vars)
    assert.equal @request.method, 'GET'

  it 'should accept JSON', ->
    @request = integration.requestParams(@vars)
    assert.equal @request.headers.Accept, '*/*'

  it 'should have Content-Type', ->
    @request = integration.requestParams(@vars)
    assert.equal @request.headers['Content-Type'], 'application/x-www-form-urlencoded' 

  it 'should append the query string to the base URL', ->
    @vars.parameter = {firstName:'Jim', lastName:'Lawson', address: '1005 East'}
    @requestParams = integration.requestParams(@vars)
    assert.equal @requestParams.url, 'http://example.com/trackingpage?firstName=Jim&lastName=Lawson&address=1005%20East'

describe 'Outbound Validate', ->

  it 'should not allow null url', ->
    error = integration.validate({ url: null })
    assert.equal error, 'url must not be blank'

  it 'should not allow undefined url', ->
    error = integration.validate({url: undefined })
    assert.equal error, 'url must not be blank'

  it 'should not allow invalid url', ->
    error = integration.validate({url: 'nooneenoo'})
    assert.equal error, 'url must be valid'

  it 'should not error when url is valid', ->
    error = integration.validate({url: 'https://www.npmjs.com'})
    assert.equal error, undefined

describe 'Outbound Success Response', ->
  
  it 'should parse outcome as success when status is in the 200 range', (done) ->
    res =
      statusCode: 200
    integration.handleResponse null, res, (err, response) ->
      assert.equal('success', response.outbound.outcome)
      done()

describe 'Outbound Failure Response', ->

  it 'should parse outcome as failure when status is not in 200 range', (done) ->
    res =
      statusCode: 403

    integration.handleResponse null, res, (err, response) ->
      assert.equal('failure',response.outbound.outcome)
      done()

  it 'should parse reason when status is not in 200 range', (done) ->
    res =
      statusCode: 403

    integration.handleResponse null, res, (err, response) ->
      assert.equal('invalid status: (403)', response.outbound.reason)
      done()

describe 'Outbound Error Response', ->

  it 'should parse outcome as error when there is an error response', (done) ->
    res =
      statusCode: 500

    integration.handleResponse {}, res, (err, response) ->
      assert.equal 'error', response.outbound.outcome
      done()

describe 'Outbound Handle', ->
  beforeEach ->
    @vars = {url: 'http://example.com/trackingpage/'}

  it 'should return an outcome of success when the status is 200', (done) ->

    nock @vars.url
      .get '/'
      .reply 200

    integration.handle @vars, (err, response) ->
      assert.equal response.outbound.outcome, 'success'
      done()

  it 'should return an outcome of error when there is an error', (done) ->
    nock @vars.url
      .get '/'
      .replyWithError 'an error occurred'

    integration.handle @vars, (err, response) ->
      assert.equal response.outbound.outcome, 'error'
      assert.equal response.outbound.reason, 'an error occurred'
      done()

  it 'should return an outcome of failure when a 404 is returned', (done) ->

    nock @vars.url
      .get '/'
      .reply 404

    integration.handle @vars, (err, response) ->
      assert.equal response.outbound.outcome, 'failure'
      assert.equal response.outbound.reason, 'invalid status: (404)'
      done()
