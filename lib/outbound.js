const querystring = require('querystring');
const validUrl = require('valid-url');
const request = require('request');

const requestParams = (vars) => {
  let encodedQuery = '';
  let url = '';
  if (vars.parameter && Object.keys(vars.parameter).length > 1) {
    encodedQuery = querystring.encode(vars.parameter);
    url = `${vars.url}?${encodedQuery}`;
  }
  else {
    url = `${vars.url}`;
  }

  return {
    method: 'GET',
    url,
    headers: {
      'Accept': '*/*',
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  };
};

const requestVariables = () => [
  { name: 'url', type: 'string', required: true, description: 'url address for tracking' },
  { name: 'parameter.*', type: 'wildcard', required: false, description: 'Additional parameter to add onto the pixel query URL' }
];


const validate = (vars) => {
  if (!vars.url) return 'url must not be blank';
  if (validUrl.isUri(vars.url) === undefined) return 'url must be valid';
};


const handle = (vars, callback) => {
  return request(requestParams(vars), (err, res) => {
    handleResponse(err, res, (error, response) => {
      if (error) return callback(error);
      return callback(null, response);
    });
  });
};


const handleResponse =  (err, res, callback) => {
  const event = {};
  if (err) {
    event.outcome = 'error';
    event.reason = err.message;
  }
  else {
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      event.outcome = 'success';
    }
    else {
      event.outcome = 'failure';
      event.reason = `invalid status: (${res.statusCode})`;
    }
  }

  return callback(null, {outbound: event});
};

const responseVariables = () => [
  { name: 'outbound.outcome', type: 'string', description: 'Success if outcome is in 200 range. Failure if not.' },
  { name: 'outbound.reason', type: 'string', description: 'This is returned when outcome is not success.' }
];


module.exports = {
  validate,
  requestVariables,
  responseVariables,
  handle,
  requestParams,
  handleResponse
};
