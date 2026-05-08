import { describe, it, expect } from '@jest/globals';
import type { APIGatewayProxyEvent } from 'aws-lambda';
import {
  createTopic,
  getOwnedTopics,
  updateTopic,
  deleteTopic,
  setDefaultTopic,
  subscribeTopic,
} from '../../src/handlers/topics';

jest.mock('../../src/lib/dynamodb', () => ({
  putTopic: jest.fn(),
  queryTopicsByOwner: jest.fn(),
  getTopicById: jest.fn(),
  updateTopicTitle: jest.fn(),
  setTopicDeleted: jest.fn(),
  setTopicDefault: jest.fn(),
  createOrFindSubscription: jest.fn(),
}));

import {
  putTopic,
  queryTopicsByOwner,
  getTopicById,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  createOrFindSubscription,
} from '../../src/lib/dynamodb';

const mockedPutTopic = putTopic as jest.MockedFunction<typeof putTopic>;
const mockedQueryTopicsByOwner = queryTopicsByOwner as jest.MockedFunction<typeof queryTopicsByOwner>;
const mockedGetTopicById = getTopicById as jest.MockedFunction<typeof getTopicById>;
const mockedUpdateTopicTitle = updateTopicTitle as jest.MockedFunction<typeof updateTopicTitle>;
const mockedSetTopicDeleted = setTopicDeleted as jest.MockedFunction<typeof setTopicDeleted>;
const mockedSetTopicDefault = setTopicDefault as jest.MockedFunction<typeof setTopicDefault>;
const mockedCreateOrFindSubscription = createOrFindSubscription as jest.MockedFunction<typeof createOrFindSubscription>;

const TOPIC_ID_1 = 'tp_2f58e8fe-9a85-44aa-9f7c-4cc0f11a4f7e';

function makeEvent(overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent {
  return {
    headers: {},
    body: null,
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    multiValueHeaders: {},
    httpMethod: 'GET',
    isBase64Encoded: false,
    path: '/',
    resource: '/',
    stageVariables: null,
    requestContext: {} as APIGatewayProxyEvent['requestContext'],
    ...overrides,
  };
}

describe('POST /api/v1/topics - createTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should create a topic and return 201', async () => {
    mockedPutTopic.mockResolvedValue(undefined);

    const event = makeEvent({
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: '생활비 가계부' }),
    });

    const result = await createTopic(event);

    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body) as Record<string, unknown>;
    expect(body.topic_id).toMatch(/^tp_/);
    expect(body.owner_id).toBe('u_1');
    expect(body.title).toBe('생활비 가계부');
    expect(body.is_default).toBe(false);
    expect(body.last_sequence).toBe(0);
    expect(body.created_at).toBeDefined();
    expect(mockedPutTopic).toHaveBeenCalledTimes(1);
    expect(mockedPutTopic).toHaveBeenCalledWith(
      expect.objectContaining({
        topic_id: expect.stringMatching(/^tp_/),
        owner_id: 'u_1',
        title: '생활비 가계부',
        is_default: false,
        last_sequence: 0,
        created_at: expect.any(String),
        updated_at: expect.any(String),
      }),
    );
  });

  it('should return 401 when x-user-id header is missing', async () => {
    const event = makeEvent({
      headers: {},
      body: JSON.stringify({ title: 'test' }),
    });

    const result = await createTopic(event);

    expect(result.statusCode).toBe(401);
    const body = JSON.parse(result.body) as Record<string, unknown>;
    expect(body.message).toBeDefined();
    expect(mockedPutTopic).not.toHaveBeenCalled();
  });

  it('should return 400 when title is missing', async () => {
    const event = makeEvent({
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({}),
    });

    const result = await createTopic(event);

    expect(result.statusCode).toBe(400);
    const body = JSON.parse(result.body) as Record<string, unknown>;
    expect(body.message).toBeDefined();
    expect(mockedPutTopic).not.toHaveBeenCalled();
  });

  it('should return 400 when title is empty string', async () => {
    const event = makeEvent({
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: '   ' }),
    });

    const result = await createTopic(event);

    expect(result.statusCode).toBe(400);
    expect(mockedPutTopic).not.toHaveBeenCalled();
  });

  it('should return 400 when body is invalid JSON', async () => {
    const event = makeEvent({
      headers: { 'x-user-id': 'u_1' },
      body: 'not-json',
    });

    const result = await createTopic(event);

    expect(result.statusCode).toBe(400);
    expect(mockedPutTopic).not.toHaveBeenCalled();
  });

  it('should return 500 when DynamoDB throws an error', async () => {
    mockedPutTopic.mockRejectedValue(new Error('DynamoDB error'));

    const event = makeEvent({
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: 'test topic' }),
    });

    const result = await createTopic(event);

    expect(result.statusCode).toBe(500);
  });
});

describe('GET /api/v1/topics/owned - getOwnedTopics', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return owned topics with 200', async () => {
    const mockTopics = [
      {
        topic_id: TOPIC_ID_1,
        owner_id: 'u_1',
        title: '생활비 가계부',
        PK: `TOPIC#${TOPIC_ID_1}`,
        SK: 'TOPIC',
        GSI1PK: 'OWNER#u_1',
        GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
        is_default: false,
        last_sequence: 0,
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
      },
    ];
    mockedQueryTopicsByOwner.mockResolvedValue(mockTopics);

    const event = makeEvent({
      headers: { 'x-user-id': 'u_1' },
    });

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body) as { topics: unknown[] };
    expect(body.topics).toEqual(mockTopics);
    expect(mockedQueryTopicsByOwner).toHaveBeenCalledWith('u_1');
  });

  it('should return 401 when x-user-id header is missing', async () => {
    const event = makeEvent({
      headers: {},
    });

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(401);
    expect(mockedQueryTopicsByOwner).not.toHaveBeenCalled();
  });
});

describe('PATCH /api/v1/topics/{topic_id} - updateTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should update title when owner updates topic', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'old title',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedUpdateTopicTitle.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      title: 'new title',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await updateTopic(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: TOPIC_ID_1 },
        body: JSON.stringify({ title: ' new title ' }),
      }),
    );

    expect(result.statusCode).toBe(200);
    expect(mockedUpdateTopicTitle).toHaveBeenCalledWith(TOPIC_ID_1, 'new title');
  });

  it('should return 404 when topic is deleted', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      deleted_at: '2026-01-01T00:00:00.000Z',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'old title',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await updateTopic(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: TOPIC_ID_1 },
        body: JSON.stringify({ title: 'new title' }),
      }),
    );

    expect(result.statusCode).toBe(404);
    expect(mockedUpdateTopicTitle).not.toHaveBeenCalled();
  });
});

describe('DELETE /api/v1/topics/{topic_id} - deleteTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should soft delete a topic', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'old title',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedSetTopicDeleted.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      deleted_at: '2026-01-01T00:00:00.000Z',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'old title',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await deleteTopic(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: TOPIC_ID_1 },
      }),
    );

    expect(result.statusCode).toBe(200);
    expect(mockedSetTopicDeleted).toHaveBeenCalledWith(TOPIC_ID_1);
  });
});

describe('POST /api/v1/topics/{topic_id}/default - setDefaultTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should unset other defaults and set target topic default', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      is_default: false,
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'old title',
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedSetTopicDefault.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_1',
      is_default: true,
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_1',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'old title',
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await setDefaultTopic(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: TOPIC_ID_1 },
      }),
    );

    expect(result.statusCode).toBe(200);
    expect(mockedSetTopicDefault).toHaveBeenCalledWith('u_1', TOPIC_ID_1);
  });
});

describe('POST /api/v1/topics/{topic_id}/subscribe - subscribeTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should subscribe with TOPIC# partition key', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_owner',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_owner',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'test topic',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedCreateOrFindSubscription.mockResolvedValue({
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'SUBSCRIBER#u_subscriber',
      GSI1PK: 'USER#u_subscriber',
      GSI1SK: `TOPIC#${TOPIC_ID_1}`,
      topic_id: TOPIC_ID_1,
      user_id: 'u_subscriber',
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await subscribeTopic(
      makeEvent({
        headers: { 'x-user-id': 'u_subscriber' },
        pathParameters: { topic_id: TOPIC_ID_1 },
      }),
    );

    expect(result.statusCode).toBe(201);
    expect(mockedCreateOrFindSubscription).toHaveBeenCalledWith(TOPIC_ID_1, 'u_subscriber');
  });

  it('should return 201 when already subscribed', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: TOPIC_ID_1,
      owner_id: 'u_owner',
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_owner',
      GSI1SK: `TOPIC#2026-01-01T00:00:00.000Z#${TOPIC_ID_1}`,
      title: 'test topic',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedCreateOrFindSubscription.mockResolvedValue({
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'SUBSCRIBER#u_subscriber',
      GSI1PK: 'USER#u_subscriber',
      GSI1SK: `TOPIC#${TOPIC_ID_1}`,
      topic_id: TOPIC_ID_1,
      user_id: 'u_subscriber',
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await subscribeTopic(
      makeEvent({
        headers: { 'x-user-id': 'u_subscriber' },
        pathParameters: { topic_id: TOPIC_ID_1 },
      }),
    );

    expect(result.statusCode).toBe(201);
  });
});
