'use strict';

const {
  createTopic,
  getOwnedTopics,
  updateTopic,
  deleteTopic,
  setDefaultTopic,
  subscribeTopic,
} = require('../../src/handlers/topics');

jest.mock('../../src/lib/dynamodb', () => ({
  putTopic: jest.fn(),
  queryTopicsByOwner: jest.fn(),
  getTopicById: jest.fn(),
  updateTopicTitle: jest.fn(),
  setTopicDeleted: jest.fn(),
  setTopicDefault: jest.fn(),
  createOrFindSubscription: jest.fn(),
}));

const {
  putTopic,
  queryTopicsByOwner,
  getTopicById,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  createOrFindSubscription,
} = require('../../src/lib/dynamodb');

const TOPIC_ID_1 = 'tp_2f58e8fe-9a85-44aa-9f7c-4cc0f11a4f7e';

describe('POST /api/v1/topics - createTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should create a topic and return 201', async () => {
    putTopic.mockResolvedValue({});

    const event = {
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: '생활비 가계부' }),
    };

    const result = await createTopic(event);

    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body);
    expect(body.topic_id).toMatch(/^tp_/);
    expect(body.owner_id).toBe('u_1');
    expect(body.title).toBe('생활비 가계부');
    expect(body.is_default).toBe(false);
    expect(body.last_sequence).toBe(0); // check last_sequence 가 뭐였지 
    expect(body.created_at).toBeDefined();
    expect(putTopic).toHaveBeenCalledTimes(1);
    expect(putTopic).toHaveBeenCalledWith(
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
    const event = {
      headers: {},
      body: JSON.stringify({ title: 'test' }),
    };

    const result = await createTopic(event);

    expect(result.statusCode).toBe(401);
    const body = JSON.parse(result.body);
    expect(body.message).toBeDefined();
    expect(putTopic).not.toHaveBeenCalled();
  });

  it('should return 400 when title is missing', async () => {
    const event = {
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({}),
    };

    const result = await createTopic(event);

    expect(result.statusCode).toBe(400);
    const body = JSON.parse(result.body);
    expect(body.message).toBeDefined();
    expect(putTopic).not.toHaveBeenCalled();
  });

  it('should return 400 when title is empty string', async () => {
    const event = {
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: '   ' }),
    };

    const result = await createTopic(event);

    expect(result.statusCode).toBe(400);
    expect(putTopic).not.toHaveBeenCalled();
  });

  it('should return 400 when body is invalid JSON', async () => {
    const event = {
      headers: { 'x-user-id': 'u_1' },
      body: 'not-json',
    };

    const result = await createTopic(event);

    expect(result.statusCode).toBe(400);
    expect(putTopic).not.toHaveBeenCalled();
  });

  it('should return 500 when DynamoDB throws an error', async () => {
    putTopic.mockRejectedValue(new Error('DynamoDB error'));

    const event = {
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: 'test topic' }),
    };

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
      },
    ];
    queryTopicsByOwner.mockResolvedValue(mockTopics);

    const event = {
      headers: { 'x-user-id': 'u_1' },
    };

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.topics).toEqual(mockTopics);
    expect(queryTopicsByOwner).toHaveBeenCalledWith('u_1');
  });

  it('should return 401 when x-user-id header is missing', async () => {
    const event = {
      headers: {},
    };

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(401);
    expect(queryTopicsByOwner).not.toHaveBeenCalled();
  });
});

describe('PATCH /api/v1/topics/{topic_id} - updateTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should update title when owner updates topic', async () => {
    getTopicById.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1' });
    updateTopicTitle.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1', title: 'new title' });

    const result = await updateTopic({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: TOPIC_ID_1 },
      body: JSON.stringify({ title: ' new title ' }),
    });

    expect(result.statusCode).toBe(200);
    expect(updateTopicTitle).toHaveBeenCalledWith(TOPIC_ID_1, 'new title');
  });

  it('should return 404 when topic is deleted', async () => {
    getTopicById.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1', deleted_at: '2026-01-01T00:00:00.000Z' });

    const result = await updateTopic({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: TOPIC_ID_1 },
      body: JSON.stringify({ title: 'new title' }),
    });

    expect(result.statusCode).toBe(404);
    expect(updateTopicTitle).not.toHaveBeenCalled();
  });
});

describe('DELETE /api/v1/topics/{topic_id} - deleteTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should soft delete a topic', async () => {
    getTopicById.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1' });
    setTopicDeleted.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1', deleted_at: '2026-01-01T00:00:00.000Z' });

    const result = await deleteTopic({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: TOPIC_ID_1 },
    });

    expect(result.statusCode).toBe(200);
    expect(setTopicDeleted).toHaveBeenCalledWith(TOPIC_ID_1);
  });
});

describe('POST /api/v1/topics/{topic_id}/default - setDefaultTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should unset other defaults and set target topic default', async () => {
    getTopicById.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1', is_default: false });
    setTopicDefault.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_1', is_default: true });

    const result = await setDefaultTopic({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: TOPIC_ID_1 },
    });

    expect(result.statusCode).toBe(200);
    expect(setTopicDefault).toHaveBeenCalledWith('u_1', TOPIC_ID_1);
  });
});

describe('POST /api/v1/topics/{topic_id}/subscribe - subscribeTopic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should subscribe with TOPIC# partition key', async () => {
    getTopicById.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_owner' });
    createOrFindSubscription.mockResolvedValue({
      PK: `TOPIC#${TOPIC_ID_1}`,
      SK: 'SUBSCRIBER#u_subscriber',
      GSI1PK: 'USER#u_subscriber',
      GSI1SK: `TOPIC#${TOPIC_ID_1}`,
      topic_id: TOPIC_ID_1,
      user_id: 'u_subscriber',
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });

    const result = await subscribeTopic({
      headers: { 'x-user-id': 'u_subscriber' },
      pathParameters: { topic_id: TOPIC_ID_1 },
    });

    expect(result.statusCode).toBe(201);
    expect(createOrFindSubscription).toHaveBeenCalledWith(TOPIC_ID_1, 'u_subscriber');
  });

  it('should return 201 when already subscribed', async () => {
    getTopicById.mockResolvedValue({ topic_id: TOPIC_ID_1, owner_id: 'u_owner' });
    createOrFindSubscription.mockResolvedValue({});

    const result = await subscribeTopic({
      headers: { 'x-user-id': 'u_subscriber' },
      pathParameters: { topic_id: TOPIC_ID_1 },
    });

    expect(result.statusCode).toBe(201);
  });
});
