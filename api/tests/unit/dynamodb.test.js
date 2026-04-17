'use strict';

const mockSend = jest.fn();
const mockFrom = jest.fn(() => ({ send: mockSend }));
const mockUuid = jest.fn();

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

jest.mock('uuid', () => ({
  v4: () => mockUuid(),
}));

const {
  queryTopicsByOwner,
  updateTopicTitle,
  setTopicDeleted,
  setTopicDefault,
  putSubscription,
  putEvent,
  updateEventData,
  setEventDeleted,
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
            ':owner_pk': 'OWNER#u_1',
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
            GSI1PK: 'SUBSCRIBER#u_1',
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
    mockUuid.mockReset();
  });

  it('putEvent should allocate next sequence and insert event item', async () => {
    mockUuid.mockReturnValueOnce('event-uuid').mockReturnValueOnce('entity-uuid');
    mockSend
      .mockResolvedValueOnce({ Attributes: { last_sequence: 1 } })
      .mockResolvedValueOnce({});

    await putEvent({
      topicId: 'tp_1',
      ownerId: 'u_owner',
      updatedBy: 'u_updater',
      kind: 'expense',
      amount: 1200,
      category: 'food',
      content: 'lunch',
      checked: false,
      occurredAt: '2026-01-01T00:00:00.000Z',
    });

    expect(mockSend).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        input: expect.objectContaining({
          Key: { pk: 'TOPIC#tp_1', sk: 'META' },
        }),
      }),
    );
    expect(mockSend).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        input: expect.objectContaining({
          Item: expect.objectContaining({
            PK: 'TOPIC#tp_1',
            SK: 'SEQ#000000000001',
            GSI1PK: 'EVENT#ev_event-uuid',
            GSI1SK: 'EVENT',
            GSI2PK: 'ENTITY#ent_entity-uuid',
            GSI2SK: 'ENTITY',
            GSI3PK: 'TOPIC#tp_1',
            GSI3SK: 'OCCURRED_AT#2026-01-01T00:00:00.000Z#EVENT#ev_event-uuid',
            entity_id: 'ent_entity-uuid',
            event_id: 'ev_event-uuid',
            topic_id: 'tp_1',
            owner_id: 'u_owner',
            updated_by: 'u_updater',
            sequence: 1,
            kind: 'expense',
            amount: 1200,
            category: 'food',
            content: 'lunch',
            checked: false,
            occurred_at: '2026-01-01T00:00:00.000Z',
            deleted_at: null,
          }),
        }),
      }),
    );
  });

  it('updateEventData should append a new event version instead of in-place update', async () => {
    mockUuid.mockReturnValueOnce('updated-event-uuid');
    mockSend
      .mockResolvedValueOnce({
        Items: [{
          PK: 'TOPIC#tp_1',
          SK: 'SEQ#000000000001',
          event_id: 'ev_1',
          entity_id: 'ent_1',
          topic_id: 'tp_1',
          owner_id: 'u_owner',
          kind: 'expense',
          amount: 1000,
          category: 'food',
          content: 'before',
          checked: false,
          occurred_at: '2026-01-01T00:00:00.000Z',
          updated_by: 'u_old',
        }],
      })
      .mockResolvedValueOnce({ Attributes: { last_sequence: 2 } })
      .mockResolvedValueOnce({});

    await updateEventData('ev_1', 'u_updater', {
      PK: 'TOPIC#tp_1',
      topic_id: 'tp_1',
      owner_id: 'u_owner',
      kind: 'expense',
      amount: null,
      category: 'food',
      content: 'after',
      checked: true,
      occurred_at: '2026-01-02T00:00:00.000Z',
    });

    expect(mockSend).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        input: expect.objectContaining({
          IndexName: 'event-id-index',
          KeyConditionExpression: 'GSI1PK = :event_pk AND GSI1SK = :event_sk',
          ExpressionAttributeValues: {
            ':event_pk': 'EVENT#ev_1',
            ':event_sk': 'EVENT',
          },
        }),
      }),
    );
    expect(mockSend).toHaveBeenNthCalledWith(
      3,
      expect.objectContaining({
        input: expect.objectContaining({
          Item: expect.objectContaining({
            PK: 'TOPIC#tp_1',
            SK: 'SEQ#000000000002',
            event_id: 'ev_updated-event-uuid',
            sequence: 2,
            updated_by: 'u_updater',
            amount: null,
            content: 'after',
            checked: true,
            GSI1PK: 'EVENT#ev_updated-event-uuid',
            GSI2PK: 'ENTITY#ent_1',
            GSI3PK: 'TOPIC#tp_1',
            GSI3SK: 'OCCURRED_AT#2026-01-02T00:00:00.000Z#EVENT#ev_updated-event-uuid',
            deleted_at: null,
          }),
        }),
      }),
    );
  });

  it('setEventDeleted should append a tombstone event', async () => {
    mockUuid.mockReturnValueOnce('deleted-event-uuid');
    mockSend
      .mockResolvedValueOnce({
        Items: [{
          PK: 'TOPIC#tp_1',
          SK: 'SEQ#000000000001',
          event_id: 'ev_1',
          entity_id: 'ent_1',
          topic_id: 'tp_1',
          owner_id: 'u_owner',
          occurred_at: '2026-01-01T00:00:00.000Z',
          updated_by: 'u_updater',
          deleted_at: null,
        }],
      })
      .mockResolvedValueOnce({ Attributes: { last_sequence: 3 } })
      .mockResolvedValueOnce({});

    await setEventDeleted('ev_1');

    expect(mockSend).toHaveBeenNthCalledWith(
      3,
      expect.objectContaining({
        input: expect.objectContaining({
          Item: expect.objectContaining({
            PK: 'TOPIC#tp_1',
            SK: 'SEQ#000000000003',
            event_id: 'ev_deleted-event-uuid',
            GSI1PK: 'EVENT#ev_deleted-event-uuid',
            GSI2PK: 'ENTITY#ent_1',
            GSI3PK: 'TOPIC#tp_1',
            updated_by: 'u_updater',
            deleted_at: expect.any(String),
          }),
        }),
      }),
    );
  });
});
