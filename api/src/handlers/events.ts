import { v4 as uuidv4 } from 'uuid';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  getTopicById,
  putEvent,
  queryEventsByTopic,
  getEventById,
  updateEventData,
  setEventDeleted,
} from '../lib/dynamodb';
import { createResponse, getUserId, parseJsonBody } from './common';

export const createEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers);
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

    const parsedBody = parseJsonBody(event.body);
    if (!parsedBody.ok) {
      return createResponse(400, { message: 'Invalid JSON body' });
    }
    const body = parsedBody.body;

    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      return createResponse(400, { message: 'event body must be an object' });
    }

    const eventItem = await putEvent({
      eventId: `ev_${uuidv4()}`,
      topicId,
      ownerId: topic.owner_id,
      updatedBy: userId,
      sequence: typeof body.sequence === 'number' ? body.sequence : 0,
      kind: body.kind !== undefined ? (body.kind as string | null) : null,
      amount: body.amount !== undefined ? (body.amount as number | null) : null,
      category: body.category !== undefined ? (body.category as string | null) : null,
      content: body.content !== undefined ? (body.content as string | null) : null,
      checked: body.checked !== undefined ? (body.checked as boolean) : false,
      occurredAt:
        body.occurred_at !== undefined
          ? (body.occurred_at as string)
          : new Date().toISOString(),
    });
    return createResponse(201, { event: eventItem });
  } catch (error) {
    console.error('Error creating event:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

export const getTopicEvents = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers);
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

    const events = await queryEventsByTopic(topicId);
    return createResponse(200, { events });
  } catch (error) {
    console.error('Error fetching events:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

export const updateEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers);
    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters?.topic_id;
    const eventId = event.pathParameters?.event_id;
    if (!topicId || !eventId) {
      return createResponse(400, { message: 'topic_id and event_id are required' });
    }

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    const existingEvent = await getEventById(eventId);
    if (!existingEvent || existingEvent.deleted_at || existingEvent.topic_id !== topicId) {
      return createResponse(404, { message: 'Event not found' });
    }

    const parsedBody = parseJsonBody(event.body);
    if (!parsedBody.ok) {
      return createResponse(400, { message: 'Invalid JSON body' });
    }
    const body = parsedBody.body;

    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      return createResponse(400, { message: 'event body must be an object' });
    }

    const updatedEvent = await updateEventData(eventId, userId, body);
    return createResponse(200, { event: updatedEvent });
  } catch (error) {
    console.error('Error updating event:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};

export const deleteEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserId(event.headers);
    if (!userId) {
      return createResponse(401, { message: 'x-user-id header is required' });
    }

    const topicId = event.pathParameters?.topic_id;
    const eventId = event.pathParameters?.event_id;
    if (!topicId || !eventId) {
      return createResponse(400, { message: 'topic_id and event_id are required' });
    }

    const topic = await getTopicById(topicId);
    if (!topic || topic.deleted_at) {
      return createResponse(404, { message: 'Topic not found' });
    }

    const existingEvent = await getEventById(eventId);
    if (!existingEvent || existingEvent.deleted_at || existingEvent.topic_id !== topicId) {
      return createResponse(404, { message: 'Event not found' });
    }

    const deletedEvent = await setEventDeleted(eventId);
    return createResponse(200, { event: deletedEvent });
  } catch (error) {
    console.error('Error deleting event:', error);
    return createResponse(500, { message: 'Internal server error' });
  }
};
