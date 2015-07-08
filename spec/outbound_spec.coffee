assert = require('chai').assert
fields = require('leadconduit-fields')
integration = require('../src/outbound')

describe 'Outbound Request', ->

  beforeEach ->
    @vars = {url: 'http://example.com/trackingpage'}
    @request = integration.request(@vars)

  it 'should have a valid URL', ->
    assert.equal @request.url, 'http://example.com/trackingpage'

  it 'should be GET', ->
    assert.equal @request.method, 'GET'

  it 'should accept JSON', ->
    assert.equal @request.headers.Accept, '*/*'

  it 'should have Content-Type', ->
    assert.equal @request.headers['Content-Type'], 'application/x-www-form-urlencoded' 

describe 'Outbound validate', ->

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

describe 'Success Response', ->
  
  it 'should parse outcome as success when status is in the 200 range', ->
    res =
      status: 200

    response = integration.response({}, {}, res)
    assert.equal('success', response.outbound.outcome)

describe 'Failure Response', ->

  it 'should parse outcome as failure when status is not in 200 range', ->
    res =
      status: 403

    response = integration.response({}, {}, res)
    assert.equal('failure',response.outbound.outcome)

  it 'should parse reason when status is not in 200 range', ->
    res =
      status: 403

    response = integration.response({}, {}, res)
    assert.equal('invalid status: (403)', response.outbound.reason)

  

