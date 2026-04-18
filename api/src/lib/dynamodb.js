'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand, GetCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

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


const topicPk = (topicId) => `TOPIC#${topicId}`;
const topicSk = 'TOPIC';
const topicOwnerGsiPk = (ownerId) => `OWNER#${ownerId}`;
const topicOwnerGsiSk = (createdAt, topicId) => `TOPIC#${createdAt}#${topicId}`;

const subscriptionPk = (topicId) => `TOPIC#${topicId}`;
const subscriptionSk = (userId) => `SUBSCRIBER#${userId}`;
const subscriptionGsiPk = (userId) => `SUBSCRIBER#${userId}`;
const subscriptionGsiSk = (topicId) => `TOPIC#${topicId}`;

// event table 에서는 topic_id 와 sequence 로 찾는 것으로 함
// “가장 많이 쓰는 조회를 PK로 만든다” ?
const eventPk = (topicId) => `TOPIC#${topicId}`; // topic 에서 sequence 로 이벤트를 찾음
const eventSk = (seq) => `SEQ#${String(seq).padStart(12, '0')}`; // sequence 로 이벤트를 찾음
const eventGsi1Pk = (eventId) => `EVENT#${eventId}`;
const eventGsi1Sk = () => 'EVENT';
const eventGsi2Pk = (entityId) => `ENTITY#${entityId}`;
const eventGsi2Sk = () => 'ENTITY';
const eventGsi3Pk = (topicId) => `TOPIC#${topicId}`;
const eventGsi3Sk = (occurredAt, eventId) => `OCCURRED_AT#${occurredAt}#EVENT#${eventId}`;

const metaSk = 'META';

async function putTopic(item) {
  const mappedItem = {
    ...item,
    PK: topicPk(item.topic_id),
    SK: topicSk,
    GSI1PK: topicOwnerGsiPk(item.owner_id),
    GSI1SK: topicOwnerGsiSk(item.created_at, item.topic_id),
  };

  await docClient.send(
    new PutCommand({
      TableName: TOPICS_TABLE,
      Item: mappedItem,
    }),
  );
}

async function queryTopicsByOwner(ownerId) {
  const result = await docClient.send(
    new QueryCommand({
      TableName: TOPICS_TABLE,
      IndexName: 'owner-index',
      KeyConditionExpression: 'GSI1PK = :owner_pk',
      FilterExpression: 'attribute_not_exists(deleted_at)',
      ExpressionAttributeValues: {
        ':owner_pk': topicOwnerGsiPk(ownerId),
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
        PK: topicPk(topicId),
        SK: topicSk,
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
        PK: topicPk(topicId),
        SK: topicSk,
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
        PK: topicPk(topicId),
        SK: topicSk,
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
        PK: topicPk(topicId),
        SK: topicSk,
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

async function createOrFindSubscription(topicId, userId) {
  // 1. 먼저 기존 구독이 있는지 조회
  const { Item: existing } = await docClient.send(
    new GetCommand({
      TableName: SUBSCRIPTIONS_TABLE,
      Key: {
        PK: subscriptionPk(topicId),
        SK: subscriptionSk(userId),
      },
    })
  );
  if (existing) {
    return existing;
  }

  // 2. 없으면 새로 생성
  const now = new Date().toISOString();
  const item = {
    PK: subscriptionPk(topicId),
    SK: subscriptionSk(userId),
    GSI1PK: subscriptionGsiPk(userId),
    GSI1SK: subscriptionGsiSk(topicId),
    topic_id: topicId,
    user_id: userId,
    created_at: now,
    updated_at: now,
  };
  await docClient.send(
    new PutCommand({
      TableName: SUBSCRIPTIONS_TABLE,
      Item: item,
      ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
    })
  );
  return item;
}


async function _nextSequence(topicId) {
  const res = await docClient.send(
    new UpdateCommand({
      TableName: EVENTS_TABLE,
      Key: {
        pk: eventPk(topicId),
        sk: metaSk,
      },
      UpdateExpression:
        'SET last_sequence = if_not_exists(last_sequence, :zero) + :inc, updated_at = :now',
      ExpressionAttributeValues: {
        ':zero': 0,
        ':inc': 1,
        ':now': new Date().toISOString(),
      },
      ReturnValues: 'UPDATED_NEW',
    }),
  );

  return res.Attributes.last_sequence;
}


async function putEvent({
  topicId,
  ownerId,
  updatedBy,
  kind,
  amount,
  category,
  content,
  checked,
  occurredAt,
}) {
  const sequence = await _nextSequence(topicId);
  const now = new Date().toISOString();
  const eventId = `ev_${uuidv4()}`;
  const entityId = `ent_${uuidv4()}`;

  const item = {
    PK: eventPk(topicId), // topic_id 와 sequence 로 이벤트를 찾음 예: 3 이후 이벤트
    SK: eventSk(sequence),

    GSI1PK: eventGsi1Pk(eventId), // 개별 event id 로 조회
    GSI1SK: eventGsi1Sk(),
    GSI2PK: eventGsi2Pk(entityId),
    GSI2SK: eventGsi2Sk(), // entity id 로 조회 (예: 8월 14일 $10 지출)
    GSI3PK: eventGsi3Pk(topicId),
    GSI3SK: eventGsi3Sk(occurredAt, eventId), // occurred at 으로 조회 (예: 8월 지출)

    entity_id: entityId,
    event_id: eventId,
    topic_id: topicId,
    owner_id: ownerId,
    updated_by: updatedBy,
    sequence,
    kind,
    amount: amount ?? null,
    category: category ?? null,
    content: content ?? null,
    checked: checked ?? false,
    occurred_at: occurredAt,
    created_at: now,
    updated_at: now,
    deleted_at: null,
  };

  await docClient.send(
    new PutCommand({
      TableName: EVENTS_TABLE,
      Item: item,
      ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
    }),
  );
  return item;
}

async function queryEventsByTopic(topicId, sequence_after = null, limit = 20) {
  // Query events for a topic, optionally after a given sequence number
  const params = {
    TableName: EVENTS_TABLE,
    KeyConditionExpression: '#pk = :pk',
    ExpressionAttributeNames: {
      '#pk': 'PK',
      '#sk': 'SK',
    },
    ExpressionAttributeValues: {
      ':pk': eventPk(topicId),
    },
    ScanIndexForward: true, // ascending order by sequence
    Limit: limit,
  };
  if (sequence_after !== null) {
    params.KeyConditionExpression += ' AND #sk > :sk';
    params.ExpressionAttributeValues[':sk'] = eventSk(sequence_after);
  }
  const result = await docClient.send(new QueryCommand(params));
  return result.Items || [];
}

// TODO testcase 확인 
async function getEventById(eventId) {
  // Query by GSI1PK (event id) and GSI1SK ('EVENT')
  const result = await docClient.send(
    new QueryCommand({
      TableName: EVENTS_TABLE,
      IndexName: 'event-id-index', // GSI1
      KeyConditionExpression: 'GSI1PK = :event_pk AND GSI1SK = :event_sk',
      ExpressionAttributeValues: {
        ':event_pk': eventGsi1Pk(eventId),
        ':event_sk': eventGsi1Sk(),
      },
      Limit: 1,
    })
  );
  return (result.Items && result.Items[0]) || null;
}

// TODO testcase 확인 
async function getEventByEntityId(entityId) {
    // Query by GSI2PK (entity id) and GSI2SK ('ENTITY')
    const result = await docClient.send(
      new QueryCommand({
        TableName: EVENTS_TABLE,
        IndexName: 'entity-id-index', // GSI2
        KeyConditionExpression: 'GSI2PK = :entity_pk AND GSI2SK = :entity_sk',
        ExpressionAttributeValues: {
          ':entity_pk': eventGsi2Pk(entityId),
          ':entity_sk': eventGsi2Sk(),
        },
      })
    );

    return result.Items || [];
}

// 실제 이벤트를 업데이트 하는게 아닌 같은 entity_id 를 가진 새로운 이벤트를 추가하는 방식으로 업데이트를 관리 (append-only)
// TODO testcase 확인
async function updateEventData(eventId, updatedBy, data) {
  // 1. 기존 이벤트 조회
  const oldEvent = await getEventById(eventId);
  if (!oldEvent) {
    throw new Error('Event not found');
  }

  // 2. 새로운 시퀀스 번호 생성
  const sequence = await _nextSequence(oldEvent.topic_id);
  const now = new Date().toISOString();
  const newEventId = `ev_${uuidv4()}`;

  // 3. 업데이트할 필드 병합 (append-only)
  const updatableFields = [
    'kind', 'amount', 'category', 'content', 'checked', 'occurred_at'
  ];
  const updated = { ...data };
  updated.updated_by = updatedBy;
  updated.updated_at = now;
  updated.sequence = sequence;
  updated.event_id = newEventId;
  updated.SK = eventSk(sequence);
  updated.GSI1PK = eventGsi1Pk(newEventId);
  updated.GSI1SK = eventGsi1Sk();
  updated.GSI2PK = eventGsi2Pk(oldEvent.entity_id);
  updated.GSI2SK = eventGsi2Sk();
  updated.GSI3PK = eventGsi3Pk(oldEvent.topic_id);
  updated.GSI3SK = eventGsi3Sk(updated.occurred_at, newEventId);
  updated.created_at = now;
  updated.deleted_at = null;

  // 4. 새 이벤트로 insert (append-only)
  await docClient.send(
    new PutCommand({
      TableName: EVENTS_TABLE,
      Item: updated,
      ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
    })
  );
  return updated;
}

// 실제 이벤트를 업데이트 하는 게 아닌 같은 entity_id 를 가진 새로운 이벤트를 추가하는 방식으로 삭제를 관리 (append-only)
// TODO testcase 확인
async function setEventDeleted(eventId) {
  // 1. 기존 이벤트 조회
  const oldEvent = await getEventById(eventId);
  if (!oldEvent) {
    throw new Error('Event not found');
  }
  
  // 2. 새로운 시퀀스 번호 생성
  const sequence = await _nextSequence(oldEvent.topic_id);
  const now = new Date().toISOString();
  const newEventId = `ev_${uuidv4()}`;

  // 3. 삭제된 이벤트로 병합 (append-only)
  const deletedEvent = {
    ...oldEvent,
    event_id: newEventId,
    SK: eventSk(sequence),
    GSI1PK: eventGsi1Pk(newEventId),
    GSI1SK: eventGsi1Sk(),
    GSI2PK: eventGsi2Pk(oldEvent.entity_id),
    GSI2SK: eventGsi2Sk(),
    GSI3PK: eventGsi3Pk(oldEvent.topic_id),
    GSI3SK: eventGsi3Sk(now, newEventId),
    updated_by: oldEvent.updated_by,
    updated_at: now,
    deleted_at: now, // 삭제된 시점 기록
  };

  // 4. 새 이벤트로 insert (append-only)
  await docClient.send(
    new PutCommand({
      TableName: EVENTS_TABLE,
      Item: deletedEvent,
      ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
    })
  );
  return deletedEvent;
}

module.exports = {
  putTopic,
  queryTopicsByOwner,
  getTopicById,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  createOrFindSubscription,
  putEvent,
  queryEventsByTopic,
  getEventById,
  getEventByEntityId,
  updateEventData,
  setEventDeleted,
};
