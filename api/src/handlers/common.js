'use strict';

const createResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(body),
});

function getUserId(headers = {}) {
  return headers['x-user-id'] || headers['X-User-Id'];
}

function parseJsonBody(rawBody) {
  try {
    return { ok: true, body: JSON.parse(rawBody || '{}') };
  } catch {
    return { ok: false, body: null };
  }
}

module.exports = {
  createResponse,
  getUserId,
  parseJsonBody,
};
