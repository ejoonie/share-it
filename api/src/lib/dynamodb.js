'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand, GetCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const clientConfig = {
  region: process.env.AWS_REGION || 'us-west-2',
};

if (process.env.DYNAMODB_ENDPOINT) {
  clientConfig.endpoint = process.env.DYNAMODB_ENDPOINT;
}

const client = new DynamoDBClient(clientConfig);
const docClient = DynamoDBDocumentClient.from(client);

const TOPICS_TABLE = process.env.TOPICS_TABLE || 't_topics-dev';
const SUBSCRIPTIONS_TABLE = process.env.SUBSCRIPTIONS_TABLE || 't_subscriptions-dev';
const EVENTS_TABLE = process.env.EVENTS_TABLE || 't_events-dev';

async function putTopic(item) {
  await docClient.send(
    new PutCommand({
      TableName: TOPICS_TABLE,
      Item: item,
    }),
  );
}

async function queryTopicsByOwner(ownerId) {
  const result = await docClient.send(
    new QueryCommand({
      TableName: TOPICS_TABLE,
      IndexName: 'owner-index',
      KeyConditionExpression: 'owner_id = :owner_id',
      FilterExpression: 'attribute_not_exists(deleted_at)',
      ExpressionAttributeValues: {
        ':owner_id': ownerId,
      },
      ScanIndexForward: false,
    }),
  );
  return result.Items || [];
}

async function getTopicById(topicId) {
  const result = await docClient.send(
    new GetCommand({
      TableName: TOPICS_TABLE,
      Key: {
        topic_id: topicId,
      },
    }),
  );
  return result.Item;
}

async function updateTopicTitle(topicId, title) {
  const updatedAt = new Date().toISOString();
  const result = await docClient.send(
    new UpdateCommand({
      TableName: TOPICS_TABLE,
      Key: {
        topic_id: topicId,
      },
      UpdateExpression: 'SET title = :title, updated_at = :updated_at',
      ExpressionAttributeValues: {
        ':title': title,
        ':updated_at': updatedAt,
      },
      ReturnValues: 'ALL_NEW',
    }),
  );
  return result.Attributes;
}

async function setTopicDeleted(topicId) {
  const deletedAt = new Date().toISOString();
  const result = await docClient.send(
    new UpdateCommand({
      TableName: TOPICS_TABLE,
      Key: {
        topic_id: topicId,
      },
      UpdateExpression: 'SET deleted_at = :deleted_at, updated_at = :updated_at, is_default = :is_default',
      ExpressionAttributeValues: {
        ':deleted_at': deletedAt,
        ':updated_at': deletedAt,
        ':is_default': false,
      },
      ReturnValues: 'ALL_NEW',
    }),
  );
  return result.Attributes;
}

async function _setTopicDefaultFlag(topicId, isDefault) {
  const updatedAt = new Date().toISOString();
  const result = await docClient.send(
    new UpdateCommand({
      TableName: TOPICS_TABLE,
      Key: {
        topic_id: topicId,
      },
      UpdateExpression: 'SET is_default = :is_default, updated_at = :updated_at',
      ExpressionAttributeValues: {
        ':is_default': isDefault,
        ':updated_at': updatedAt,
      },
      ReturnValues: 'ALL_NEW',
    }),
  );
  return result.Attributes;
}

async function setTopicDefault(ownerId, topicId) {
  const ownerTopics = await queryTopicsByOwner(ownerId);

  await Promise.all(
    ownerTopics
      .filter((ownerTopic) => ownerTopic.topic_id !== topicId)
      .map((ownerTopic) => _setTopicDefaultFlag(ownerTopic.topic_id, false)),
  );

  return _setTopicDefaultFlag(topicId, true);
}

async function putSubscription(topicId, userId) {
  const now = new Date().toISOString();
  const item = {
    pk: `TOPIC#${topicId}`,
    sk: `USER#${userId}`,
    topic_id: topicId,
    user_id: userId,
    created_at: now,
    updated_at: now,
  };

  await docClient.send(
    new PutCommand({
      TableName: SUBSCRIPTIONS_TABLE,
      Item: item,
      ConditionExpression: 'attribute_not_exists(pk) AND attribute_not_exists(sk)',
    }),
  );
  return item;
}

async function putEvent({
  eventId,
  topicId,
  ownerId,
  updatedBy,
  sequence,
  kind,
  amount,
  category,
  content,
  checked,
  occurredAt,
}) {
  const item = {
    event_id: eventId,
    topic_id: topicId,
    owner_id: ownerId,
    update_by: updatedBy,
    sequence,
    kind,
    amount: amount ?? null,
    category: category ?? null,
    content: content ?? null,
    checked: checked ?? false,
    occurred_at: occurredAt,
  };

  await docClient.send(
    new PutCommand({
      TableName: EVENTS_TABLE,
      Item: item,
    }),
  );
  return item;
}

async function queryEventsByTopic(topicId) {
  const result = await docClient.send(
    new QueryCommand({
      TableName: EVENTS_TABLE,
      IndexName: 'topic-index',
      KeyConditionExpression: 'topic_id = :topic_id',
      FilterExpression: 'attribute_not_exists(deleted_at)',
      ExpressionAttributeValues: {
        ':topic_id': topicId,
      },
      ScanIndexForward: false,
    }),
  );
  return result.Items || [];
}

async function getEventById(eventId) {
  const result = await docClient.send(
    new GetCommand({
      TableName: EVENTS_TABLE,
      Key: {
        event_id: eventId,
      },
    }),
  );
  return result.Item;
}

async function updateEventData(eventId, updatedBy, data) {
  const expressionValues = {
    ':updated_by': updatedBy,
  };
  const updateExpressions = ['update_by = :updated_by'];

  const updatableFields = ['sequence', 'kind', 'amount', 'category', 'content', 'checked', 'occurred_at'];
  updatableFields.forEach((field) => {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      const valueKey = `:${field}`;
      expressionValues[valueKey] = data[field];
      updateExpressions.push(`${field} = ${valueKey}`);
    }
  });

  const result = await docClient.send(
    new UpdateCommand({
      TableName: EVENTS_TABLE,
      Key: {
        event_id: eventId,
      },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeValues: expressionValues,
      ReturnValues: 'ALL_NEW',
    }),
  );
  return result.Attributes;
}

async function setEventDeleted(eventId) {
  const deletedAt = new Date().toISOString();
  const result = await docClient.send(
    new UpdateCommand({
      TableName: EVENTS_TABLE,
      Key: {
        event_id: eventId,
      },
      UpdateExpression: 'SET deleted_at = :deleted_at, updated_at = :updated_at',
      ExpressionAttributeValues: {
        ':deleted_at': deletedAt,
        ':updated_at': deletedAt,
      },
      ReturnValues: 'ALL_NEW',
    }),
  );
  return result.Attributes;
}

module.exports = {
  putTopic,
  queryTopicsByOwner,
  getTopicById,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  putSubscription,
  putEvent,
  queryEventsByTopic,
  getEventById,
  updateEventData,
  setEventDeleted,
};
