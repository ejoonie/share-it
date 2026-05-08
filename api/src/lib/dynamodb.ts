import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
  GetCommand,
  UpdateCommand,
} from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { keysToCamel } from '../utils/case';

export interface TopicItem {
  PK: string;
  SK: string;
  GSI1PK: string;
  GSI1SK: string;
  topic_id: string;
  owner_id: string;
  title: string;
  is_default: boolean;
  last_sequence: number;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface SubscriptionItem {
  PK: string;
  SK: string;
  GSI1PK: string;
  GSI1SK: string;
  topic_id: string;
  user_id: string;
  created_at: string;
  updated_at: string;
}

export interface EventItem {
  PK: string;
  SK: string;
  GSI1PK: string;
  GSI1SK: string;
  GSI2PK: string;
  GSI2SK: string;
  GSI3PK: string;
  GSI3SK: string;
  entity_id: string;
  event_id: string;
  topic_id: string;
  owner_id: string;
  updated_by: string;
  sequence: number;
  kind: string | null;
  amount: number | null;
  category: string | null;
  content: string | null;
  checked: boolean;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null | undefined;
}

export interface PutTopicInput {
  topic_id: string;
  owner_id: string;
  title: string;
  is_default: boolean;
  last_sequence: number;
  created_at: string;
  updated_at: string;
}

export interface PutEventInput {
  topicId: string;
  ownerId: string;
  updatedBy: string;
  kind?: string | null;
  amount?: number | null;
  category?: string | null;
  content?: string | null;
  checked?: boolean;
  occurredAt?: string;
  entityId?: string;
  createdAt?: string;
  deletedAt?: string | null;
  [key: string]: unknown;
}

const clientConfig: { region: string; endpoint?: string } = {
  region: process.env.AWS_REGION ?? 'us-west-2',
};

if (process.env.DYNAMODB_ENDPOINT) {
  clientConfig.endpoint = process.env.DYNAMODB_ENDPOINT;
}

const client = new DynamoDBClient(clientConfig);
const docClient = DynamoDBDocumentClient.from(client);

const TOPICS_TABLE = process.env.TOPICS_TABLE ?? 't_topics-dev';
const SUBSCRIPTIONS_TABLE = process.env.SUBSCRIPTIONS_TABLE ?? 't_subscriptions-dev';
const EVENTS_TABLE = process.env.EVENTS_TABLE ?? 't_events-dev';


const topicPk = (topicId: string): string => `TOPIC#${topicId}`;
const topicSk = 'TOPIC';
const topicOwnerGsiPk = (ownerId: string): string => `OWNER#${ownerId}`;
const topicOwnerGsiSk = (createdAt: string, topicId: string): string => `TOPIC#${createdAt}#${topicId}`;

const subscriptionPk = (topicId: string): string => `TOPIC#${topicId}`;
const subscriptionSk = (userId: string): string => `SUBSCRIBER#${userId}`;
const subscriptionGsiPk = (userId: string): string => `SUBSCRIBER#${userId}`;
const subscriptionGsiSk = (topicId: string): string => `TOPIC#${topicId}`;

// event table 에서는 topic_id 와 sequence 로 찾는 것으로 함
// "가장 많이 쓰는 조회를 PK로 만든다" ?
const eventPk = (topicId: string): string => `TOPIC#${topicId}`; // topic 에서 sequence 로 이벤트를 찾음
const eventSk = (seq: number): string => `SEQ#${String(seq).padStart(12, '0')}`; // sequence 로 이벤트를 찾음
const eventGsi1Pk = (eventId: string): string => `EVENT#${eventId}`;
const eventGsi1Sk = (): string => 'EVENT';
const eventGsi2Pk = (entityId: string): string => `ENTITY#${entityId}`;
const eventGsi2Sk = (): string => 'ENTITY';
const eventGsi3Pk = (topicId: string): string => `TOPIC#${topicId}`;
const eventGsi3Sk = (occurredAt: string, eventId: string): string =>
  `OCCURRED_AT#${occurredAt}#EVENT#${eventId}`;

const metaSk = 'META';

export async function putTopic(item: PutTopicInput): Promise<void> {
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

export async function queryTopicsByOwner(ownerId: string): Promise<TopicItem[]> {
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
  return (result.Items ?? []) as TopicItem[];
}

export async function getTopicById(topicId: string): Promise<TopicItem | undefined> {
  const result = await docClient.send(
    new GetCommand({
      TableName: TOPICS_TABLE,
      Key: {
        PK: topicPk(topicId),
        SK: topicSk,
      },
    }),
  );
  return result.Item as TopicItem | undefined;
}

export async function updateTopicTitle(topicId: string, title: string): Promise<TopicItem> {
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
  return result.Attributes as TopicItem;
}

export async function setTopicDeleted(topicId: string): Promise<TopicItem> {
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
  return result.Attributes as TopicItem;
}

async function _setTopicDefaultFlag(topicId: string, isDefault: boolean): Promise<TopicItem> {
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
  return result.Attributes as TopicItem;
}

export async function setTopicDefault(ownerId: string, topicId: string): Promise<TopicItem> {
  const ownerTopics = await queryTopicsByOwner(ownerId);

  await Promise.all(
    ownerTopics
      .filter((ownerTopic) => ownerTopic.topic_id !== topicId)
      .map((ownerTopic) => _setTopicDefaultFlag(ownerTopic.topic_id, false)),
  );

  return _setTopicDefaultFlag(topicId, true);
}

export async function createOrFindSubscription(
  topicId: string,
  userId: string,
): Promise<SubscriptionItem> {
  // 1. 먼저 기존 구독이 있는지 조회
  const { Item: existing } = await docClient.send(
    new GetCommand({
      TableName: SUBSCRIPTIONS_TABLE,
      Key: {
        PK: subscriptionPk(topicId),
        SK: subscriptionSk(userId),
      },
    }),
  );
  if (existing) {
    return existing as SubscriptionItem;
  }

  // 2. 없으면 새로 생성
  const now = new Date().toISOString();
  const item: SubscriptionItem = {
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
    }),
  );
  return item;
}


async function _nextSequence(topicId: string): Promise<number> {
  const res = await docClient.send(
    new UpdateCommand({
      TableName: EVENTS_TABLE,
      Key: {
        PK: eventPk(topicId),
        SK: metaSk,
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

  return (res.Attributes as { last_sequence: number }).last_sequence;
}


export async function putEvent(input: PutEventInput): Promise<EventItem> {
  const {
    topicId,
    ownerId,
    updatedBy,
    kind = null,
    amount = null,
    category = null,
    content = null,
    checked = false,
    occurredAt,
    entityId,
    createdAt,
    deletedAt = null,
  } = input;

  const sequence = await _nextSequence(topicId);
  const now = new Date().toISOString();
  const eventId = `ev_${uuidv4()}`;
  const entityIdValue = entityId ?? `ent_${uuidv4()}`; // update 시에는 기존 entity_id 사용, 새로 생성하는 경우에는 새로운 entity_id 생성
  const occurredAtValue = occurredAt ?? now;

  const item: EventItem = {
    PK: eventPk(topicId), // topic_id 와 sequence 로 이벤트를 찾음 예: 3 이후 이벤트
    SK: eventSk(sequence),

    GSI1PK: eventGsi1Pk(eventId), // 개별 event id 로 조회
    GSI1SK: eventGsi1Sk(),
    GSI2PK: eventGsi2Pk(entityIdValue),
    GSI2SK: eventGsi2Sk(), // entity id 로 조회 (예: 8월 14일 $10 지출)
    GSI3PK: eventGsi3Pk(topicId),
    GSI3SK: eventGsi3Sk(occurredAtValue, eventId), // occurred at 으로 조회 (예: 8월 지출)

    entity_id: entityIdValue,
    event_id: eventId,
    topic_id: topicId,
    owner_id: ownerId,
    updated_by: updatedBy,
    sequence,
    kind: kind ?? null,
    amount: amount ?? null,
    category: category ?? null,
    content: content ?? null,
    checked: checked ?? false,
    occurred_at: occurredAtValue,
    created_at: createdAt ?? now, // update 시에는 기존 created_at 유지, 새로 생성하는 경우에는 현재 시간 사용
    updated_at: now,
    deleted_at: deletedAt,
  };

  console.log('entityId:', entityIdValue);
  console.log('deletedAt:', deletedAt);

  await docClient.send(
    new PutCommand({
      TableName: EVENTS_TABLE,
      Item: item,
      ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
    }),
  );
  return item;
}

export async function queryEventsByTopic(
  topicId: string,
  sequence_after: number | null = null,
  limit = 20,
): Promise<EventItem[]> {
  // Query events for a topic, optionally after a given sequence number
  const params: {
    TableName: string;
    KeyConditionExpression: string;
    ExpressionAttributeNames: Record<string, string>;
    ExpressionAttributeValues: Record<string, unknown>;
    ScanIndexForward: boolean;
    Limit: number;
  } = {
    TableName: EVENTS_TABLE,
    KeyConditionExpression: '#pk = :pk',
    ExpressionAttributeNames: {
      '#pk': 'PK',
    },
    ExpressionAttributeValues: {
      ':pk': eventPk(topicId),
    },
    ScanIndexForward: true, // ascending order by sequence
    Limit: limit,
  };
  if (sequence_after !== null) {
    params.KeyConditionExpression += ' AND #sk > :sk';
    params.ExpressionAttributeNames['#sk'] = 'SK';
    params.ExpressionAttributeValues[':sk'] = eventSk(sequence_after);
  }
  const result = await docClient.send(new QueryCommand(params));
  return (result.Items ?? []) as EventItem[];
}

// TODO testcase 확인
export async function getEventById(eventId: string): Promise<EventItem | null> {
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
    }),
  );
  return ((result.Items && result.Items[0]) ?? null) as EventItem | null;
}

// TODO testcase 확인
export async function getEventByEntityId(entityId: string): Promise<EventItem[]> {
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
    }),
  );

  return (result.Items ?? []) as EventItem[];
}

// 실제 이벤트를 업데이트 하는게 아닌 같은 entity_id 를 가진 새로운 이벤트를 추가하는 방식으로 업데이트를 관리 (append-only)
// TODO testcase 확인
export async function updateEventData(
  eventId: string,
  updatedBy: string,
  data: Record<string, unknown>,
): Promise<EventItem> {
  // 기존 이벤트를 조회해서 entity_id 등 필드를 가져옴
  const existingEvent = await getEventById(eventId);
  if (!existingEvent) {
    throw new Error(`Event not found: ${eventId}`);
  }
  const camelData = keysToCamel(data) as Partial<PutEventInput>;
  const updated = await putEvent({
    ...camelData,
    topicId: camelData.topicId ?? existingEvent.topic_id,
    ownerId: camelData.ownerId ?? existingEvent.owner_id,
    updatedBy,
    entityId: existingEvent.entity_id, // 기존 entityId 사용
  });
  return updated;
}

// 실제 이벤트를 업데이트 하는 게 아닌 같은 entity_id 를 가진 새로운 이벤트를 추가하는 방식으로 삭제를 관리 (append-only)
// TODO testcase 확인
export async function setEventDeleted(entityId: string, updatedBy?: string): Promise<EventItem> {
  const events = await getEventByEntityId(entityId);
  const lastEvent = events.sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
  )[0];
  const camelLastEvent = keysToCamel(lastEvent) as Partial<PutEventInput>;
  const deleted = await putEvent({
    ...camelLastEvent,
    topicId: camelLastEvent.topicId ?? '',
    ownerId: camelLastEvent.ownerId ?? '',
    updatedBy: updatedBy ?? camelLastEvent.updatedBy ?? '',
    deletedAt: new Date().toISOString(), // deleted_at 설정
  });
  return deleted;
}
