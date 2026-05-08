import { v4 as uuidv4 } from 'uuid';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  putTopic,
  queryTopicsByOwner,
  getTopicById,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  createOrFindSubscription,
} from '../lib/dynamodb';
import { createResponse, getUserId, parseJsonBody } from './common';

export const createTopic = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers ?? {});

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const parsedBody = parseJsonBody(event.body);
    if (!parsedBody.ok) {
      return createResponse(400, { message: 'Invalid JSON body' });
    }
    const body = parsedBody.body ?? {};

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

export const getOwnedTopics = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers ?? {});

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

export const updateTopic = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers ?? {});

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters?.topic_id;
    if (!topicId) {
      return createResponse(400, { message: 'topic_id is required' });
    }

    const parsedBody = parseJsonBody(event.body);
    if (!parsedBody.ok) {
      return createResponse(400, { message: 'Invalid JSON body' });
    }
    const body = parsedBody.body ?? {};

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

export const deleteTopic = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers ?? {});

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters?.topic_id;
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

export const setDefaultTopic = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers ?? {});

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters?.topic_id;
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

export const subscribeTopic = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers ?? {});

    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters?.topic_id;
    if (!topicId) {
      return createResponse(400, { message: 'topic_id is required' });
    }

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    const subscriptionItem = await createOrFindSubscription(topicId, userId);

    return createResponse(201, { subscription: subscriptionItem });
  } catch (error) {
    if (error && typeof error === 'object' && (error as { name?: string }).name === 'ConditionalCheckFailedException') {
      return createResponse(409, { message: 'Already subscribed' });
    }
    console.error('Error subscribing topic:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};
