'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const clientConfig = {
  region: process.env.AWS_REGION || 'us-west-2',
};

if (process.env.DYNAMODB_ENDPOINT) {
  clientConfig.endpoint = process.env.DYNAMODB_ENDPOINT;
}

const client = new DynamoDBClient(clientConfig);
const docClient = DynamoDBDocumentClient.from(client);

const TOPICS_TABLE = process.env.TOPICS_TABLE || 't_topics-development';

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
      ExpressionAttributeValues: {
        ':owner_id': ownerId,
      },
      ScanIndexForward: false,
    }),
  );
  return result.Items || [];
}

module.exports = { putTopic, queryTopicsByOwner };
