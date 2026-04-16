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
  putEvent,
  updateEventData,
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
          KeyConditionExpression: 'GSI1PK = :owner_pk',
          FilterExpression: 'attribute_not_exists(deleted_at)',
          ExpressionAttributeValues: {
            ':owner_pk': 'USER#u_1',
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
          Key: { PK: 'TOPIC#tp_1', SK: 'TOPIC' },
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
          Key: { PK: 'TOPIC#tp_1', SK: 'TOPIC' },
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

    const updatedTopicIds = updateCalls.map(([command]) => command.input.Key.PK);
    expect(updatedTopicIds).toEqual(expect.arrayContaining(['TOPIC#tp_other_1', 'TOPIC#tp_other_2', 'TOPIC#tp_target']));
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
            PK: 'TOPIC#tp_1',
            SK: 'SUBSCRIBER#u_1',
            GSI1PK: 'USER#u_1',
            GSI1SK: 'TOPIC#tp_1',
            topic_id: 'tp_1',
            user_id: 'u_1',
            created_at: expect.any(String),
            updated_at: expect.any(String),
          }),
        }),
      }),
    );
    expect(result.PK).toBe('TOPIC#tp_1');
    expect(result.SK).toBe('SUBSCRIBER#u_1');
  });
});

describe('lib/dynamodb - events', () => {
  beforeEach(() => {
    mockSend.mockReset();
  });

  it('putEvent should construct event item without data field', async () => {
    mockSend.mockResolvedValue({});

    await putEvent({
      eventId: 'ev_1',
      topicId: 'tp_1',
      ownerId: 'u_owner',
      updatedBy: 'u_updater',
      sequence: 1,
      kind: 'expense',
      amount: 1200,
      category: 'food',
      content: 'lunch',
      checked: false,
      occurredAt: '2026-01-01T00:00:00.000Z',
    });

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        input: expect.objectContaining({
          Item: expect.objectContaining({
            PK: 'EVENT#ev_1',
            SK: 'EVENT',
            GSI1PK: 'TOPIC#tp_1',
            GSI1SK: 'OCCURRED_AT#2026-01-01T00:00:00.000Z#EVENT#ev_1',
            event_id: 'ev_1',
            topic_id: 'tp_1',
            owner_id: 'u_owner',
            update_by: 'u_updater',
            sequence: 1,
            kind: 'expense',
            amount: 1200,
            category: 'food',
            content: 'lunch',
            checked: false,
            occurred_at: '2026-01-01T00:00:00.000Z',
          }),
        }),
      }),
    );
  });

  it('updateEventData should set update_by and provided fields', async () => {
    mockSend.mockResolvedValue({ Attributes: { event_id: 'ev_1' } });

    await updateEventData('ev_1', 'u_updater', { amount: null, checked: true });

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        input: expect.objectContaining({
          Key: { PK: 'EVENT#ev_1', SK: 'EVENT' },
          ExpressionAttributeValues: expect.objectContaining({
            ':updated_by': 'u_updater',
            ':amount': null,
            ':checked': true,
          }),
        }),
      }),
    );
  });
});
