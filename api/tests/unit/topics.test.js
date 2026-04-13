'use strict';

const { createTopic, getOwnedTopics } = require('../../src/handlers/topics');

jest.mock('../../src/lib/dynamodb', () => ({
  putTopic: jest.fn(),
  queryTopicsByOwner: jest.fn(),
}));

const { putTopic, queryTopicsByOwner } = require('../../src/lib/dynamodb');

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
    expect(body.last_sequence).toBe(0);
    expect(body.created_at).toBeDefined();
    expect(putTopic).toHaveBeenCalledTimes(1);
    expect(putTopic).toHaveBeenCalledWith(
      expect.objectContaining({
        topic_id: expect.stringMatching(/^tp_/),
        owner_id: 'u_1',
        title: '생활비 가계부',
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

  it('should trim whitespace from title', async () => {
    putTopic.mockResolvedValue({});

    const event = {
      headers: { 'x-user-id': 'u_1' },
      body: JSON.stringify({ title: '  test topic  ' }),
    };

    const result = await createTopic(event);

    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body);
    expect(body.title).toBe('test topic');
  });
});

describe('GET /api/v1/topics/owned - getOwnedTopics', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return owned topics with 200', async () => {
    const mockTopics = [
      {
        topic_id: 'tp_2f58e8fe-9a85-44aa-9f7c-4cc0f11a4f7e',
        owner_id: 'u_1',
        title: '생활비 가계부',
        last_sequence: 0,
        created_at: '2026-04-13T20:30:00.000Z',
        updated_at: '2026-04-13T20:30:00.000Z',
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

  it('should return empty topics array when user has no topics', async () => {
    queryTopicsByOwner.mockResolvedValue([]);

    const event = {
      headers: { 'x-user-id': 'u_1' },
    };

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.topics).toEqual([]);
  });

  it('should return 401 when x-user-id header is missing', async () => {
    const event = {
      headers: {},
    };

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(401);
    const body = JSON.parse(result.body);
    expect(body.message).toBeDefined();
    expect(queryTopicsByOwner).not.toHaveBeenCalled();
  });

  it('should return 500 when DynamoDB throws an error', async () => {
    queryTopicsByOwner.mockRejectedValue(new Error('DynamoDB error'));

    const event = {
      headers: { 'x-user-id': 'u_1' },
    };

    const result = await getOwnedTopics(event);

    expect(result.statusCode).toBe(500);
  });
});
