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

const { queryTopicsByOwner } = require('../../src/lib/dynamodb');

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
