'use strict';

const { v4: uuidv4 } = require('uuid');
const { putTopic, queryTopicsByOwner } = require('../lib/dynamodb');

const createResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(body),
});

module.exports.createTopic = async (event) => {
  try {
    const headers = event.headers || {};
    const userId = headers['x-user-id'] || headers['X-User-Id'];

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    let body;
    try {
      body = JSON.parse(event.body || '{}');
    } catch {
      return createResponse(400, { message: 'Invalid JSON body' });
    }

    const { title } = body;
    if (!title || typeof title !== 'string' || title.trim() === '') {
      return createResponse(400, { message: 'title is required' });
    }

    const topicId = `tp_${uuidv4()}`;
    const now = new Date().toISOString();
    const trimmedTitle = title.trim();

    const item = {
      topic_id: topicId,
      owner_id: userId,
      title: trimmedTitle,
      last_sequence: 0,
      created_at: now,
      updated_at: now,
    };

    await putTopic(item);

    return createResponse(201, {
      topic_id: topicId,
      owner_id: userId,
      title: trimmedTitle,
      last_sequence: 0,
      created_at: now,
    });
  } catch (error) {
    console.error('Error creating topic:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

module.exports.getOwnedTopics = async (event) => {
  try {
    const headers = event.headers || {};
    const userId = headers['x-user-id'] || headers['X-User-Id'];

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topics = await queryTopicsByOwner(userId);

    return createResponse(200, { topics });
  } catch (error) {
    console.error('Error fetching owned topics:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};
