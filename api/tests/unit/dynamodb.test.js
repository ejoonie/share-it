'use strict';

const mockSend = jest.fn();
const mockFrom = jest.fn(() => ({ send: mockSend }));

jest.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: jest.fn(),
}));

jest.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: {
    from: mockFrom,
  },
  PutCommand: class PutCommand {
    constructor(input) {
      this.input = input;
    }
  },
  QueryCommand: class QueryCommand {
    constructor(input) {
      this.input = input;
    }
  },
  GetCommand: class GetCommand {
    constructor(input) {
      this.input = input;
    }
  },
  UpdateCommand: class UpdateCommand {
    constructor(input) {
      this.input = input;
    }
  },
}));

const {
  queryTopicsByOwner,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  putSubscription,
} = require('../../src/lib/dynamodb');

describe('lib/dynamodb - queryTopicsByOwner', () => {
  beforeEach(() => {
    mockSend.mockReset();
  });

  it('should use filter expression to exclude soft-deleted topics', async () => {
    mockSend.mockResolvedValue({ Items: [] });

    await queryTopicsByOwner('u_1');

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        input: expect.objectContaining({
          TableName: expect.any(String),
          IndexName: 'owner-index',
          KeyConditionExpression: 'owner_id = :owner_id',
          FilterExpression: 'attribute_not_exists(deleted_at)',
          ExpressionAttributeValues: {
            ':owner_id': 'u_1',
          },
        }),
      }),
    );
  });
});

describe('lib/dynamodb - topic mutators', () => {
  beforeEach(() => {
    mockSend.mockReset();
  });

  it('updateTopicTitle should set updated_at internally', async () => {
    mockSend.mockResolvedValue({ Attributes: { topic_id: 'tp_1' } });

    await updateTopicTitle('tp_1', 'new');

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        input: expect.objectContaining({
          Key: { topic_id: 'tp_1' },
          ExpressionAttributeValues: expect.objectContaining({
            ':title': 'new',
            ':updated_at': expect.any(String),
          }),
        }),
      }),
    );
  });

  it('setTopicDeleted should set deleted_at and updated_at internally', async () => {
    mockSend.mockResolvedValue({ Attributes: { topic_id: 'tp_1' } });

    await setTopicDeleted('tp_1');

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        input: expect.objectContaining({
          Key: { topic_id: 'tp_1' },
          ExpressionAttributeValues: expect.objectContaining({
            ':deleted_at': expect.any(String),
            ':updated_at': expect.any(String),
          }),
        }),
      }),
    );
  });

  it('setTopicDefault should unset other active topics and set target topic', async () => {
    mockSend
      .mockResolvedValueOnce({
        Items: [
          { topic_id: 'tp_target', owner_id: 'u_1', is_default: false },
          { topic_id: 'tp_other_1', owner_id: 'u_1', is_default: true },
          { topic_id: 'tp_other_2', owner_id: 'u_1', is_default: false },
        ],
      })
      .mockResolvedValue({ Attributes: {} });

    await setTopicDefault('u_1', 'tp_target');

    const updateCalls = mockSend.mock.calls.slice(1);
    expect(updateCalls).toHaveLength(3);

    const updatedTopicIds = updateCalls.map(([command]) => command.input.Key.topic_id);
    expect(updatedTopicIds).toEqual(expect.arrayContaining(['tp_other_1', 'tp_other_2', 'tp_target']));
  });
});

describe('lib/dynamodb - putSubscription', () => {
  beforeEach(() => {
    mockSend.mockReset();
  });

  it('should build key/timestamps from topic_id and user_id', async () => {
    mockSend.mockResolvedValue({});

    const result = await putSubscription('tp_1', 'u_1');

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        input: expect.objectContaining({
          Item: expect.objectContaining({
            pk: 'TOPIC#tp_1',
            sk: 'USER#u_1',
            topic_id: 'tp_1',
            user_id: 'u_1',
            created_at: expect.any(String),
            updated_at: expect.any(String),
          }),
        }),
      }),
    );
    expect(result.pk).toBe('TOPIC#tp_1');
    expect(result.sk).toBe('USER#u_1');
  });
});
