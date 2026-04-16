'use strict';

const { v4: uuidv4 } = require('uuid');
const {
  putTopic,
  queryTopicsByOwner,
  getTopicById,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  putSubscription,
} = require('../lib/dynamodb');

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
      is_default: false,
      last_sequence: 0,
      created_at: now,
      updated_at: now,
    };

    await putTopic(item);

    return createResponse(201, {
      topic_id: topicId,
      owner_id: userId,
      title: trimmedTitle,
      is_default: false,
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

module.exports.updateTopic = async (event) => {
  try {
    const headers = event.headers || {};
    const userId = headers['x-user-id'] || headers['X-User-Id'];

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters && event.pathParameters.topic_id;
    if (!topicId) {
      return createResponse(400, { message: 'topic_id is required' });
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

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    if (topic.owner_id !== userId) {
      return createResponse(403, { message: 'Forbidden' });
    }

    const updatedTopic = await updateTopicTitle(topicId, title.trim());

    return createResponse(200, { topic: updatedTopic });
  } catch (error) {
    console.error('Error updating topic:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

module.exports.deleteTopic = async (event) => {
  try {
    const headers = event.headers || {};
    const userId = headers['x-user-id'] || headers['X-User-Id'];

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters && event.pathParameters.topic_id;
    if (!topicId) {
      return createResponse(400, { message: 'topic_id is required' });
    }

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    if (topic.owner_id !== userId) {
      return createResponse(403, { message: 'Forbidden' });
    }

    const deletedTopic = await setTopicDeleted(topicId);

    return createResponse(200, { topic: deletedTopic });
  } catch (error) {
    console.error('Error deleting topic:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

module.exports.setDefaultTopic = async (event) => {
  try {
    const headers = event.headers || {};
    const userId = headers['x-user-id'] || headers['X-User-Id'];

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters && event.pathParameters.topic_id;
    if (!topicId) {
      return createResponse(400, { message: 'topic_id is required' });
    }

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    if (topic.owner_id !== userId) {
      return createResponse(403, { message: 'Forbidden' });
    }

    const defaultTopic = await setTopicDefault(userId, topicId);

    return createResponse(200, { topic: defaultTopic });
  } catch (error) {
    console.error('Error setting default topic:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

module.exports.subscribeTopic = async (event) => {
  try {
    const headers = event.headers || {};
    const userId = headers['x-user-id'] || headers['X-User-Id'];

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters && event.pathParameters.topic_id;
    if (!topicId) {
      return createResponse(400, { message: 'topic_id is required' });
    }

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    const subscriptionItem = await putSubscription(topicId, userId);

    return createResponse(201, { subscription: subscriptionItem });
  } catch (error) {
    if (error && error.name === 'ConditionalCheckFailedException') {
      return createResponse(409, { message: 'Already subscribed' });
    }
    console.error('Error subscribing topic:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};
