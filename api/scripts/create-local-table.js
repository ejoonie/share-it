'use strict';

/**
 * 로컬 DynamoDB에 topics/subscriptions/events 테이블을 생성하는 셋업 스크립트.
 * 실행: node scripts/create-local-table.js
 * 사전 조건: docker compose up -d 로 DynamoDB Local이 실행 중이어야 합니다.
 */

const { DynamoDBClient, CreateTableCommand, ListTablesCommand } = require('@aws-sdk/client-dynamodb');

const ENDPOINT = process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
const REGION = process.env.AWS_REGION || 'us-west-2';
const TOPICS_TABLE_NAME = process.env.TOPICS_TABLE || 't_topics-dev';
const SUBSCRIPTIONS_TABLE_NAME = process.env.SUBSCRIPTIONS_TABLE || 't_subscriptions-dev';
const EVENTS_TABLE_NAME = process.env.EVENTS_TABLE || 't_events-dev';

const client = new DynamoDBClient({
  region: REGION,
  endpoint: ENDPOINT,
  credentials: { accessKeyId: 'local', secretAccessKey: 'local' }, // 로컬 전용 더미 자격증명
});

async function run() {
  // 이미 테이블이 있으면 건너뜀
  const { TableNames } = await client.send(new ListTablesCommand({}));
  if (!TableNames.includes(TOPICS_TABLE_NAME)) {
    await client.send(
      new CreateTableCommand({
        TableName: TOPICS_TABLE_NAME,
        BillingMode: 'PAY_PER_REQUEST',
        AttributeDefinitions: [
          { AttributeName: 'PK', AttributeType: 'S' },
          { AttributeName: 'SK', AttributeType: 'S' },
          { AttributeName: 'GSI1PK', AttributeType: 'S' },
          { AttributeName: 'GSI1SK', AttributeType: 'S' },
        ],
        KeySchema: [
          { AttributeName: 'PK', KeyType: 'HASH' },
          { AttributeName: 'SK', KeyType: 'RANGE' },
        ],
        GlobalSecondaryIndexes: [
          {
            IndexName: 'owner-index',
            KeySchema: [
              { AttributeName: 'GSI1PK', KeyType: 'HASH' },
              { AttributeName: 'GSI1SK', KeyType: 'RANGE' },
            ],
            Projection: { ProjectionType: 'ALL' },
          },
        ],
      }),
    );
    console.log(`✓ Table "${TOPICS_TABLE_NAME}" created successfully.`);
  } else {
    console.log(`✓ Table "${TOPICS_TABLE_NAME}" already exists — skipping.`);
  }

  if (!TableNames.includes(SUBSCRIPTIONS_TABLE_NAME)) {
    await client.send(
      new CreateTableCommand({
        TableName: SUBSCRIPTIONS_TABLE_NAME,
        BillingMode: 'PAY_PER_REQUEST',
        AttributeDefinitions: [
          { AttributeName: 'PK', AttributeType: 'S' },
          { AttributeName: 'SK', AttributeType: 'S' },
          { AttributeName: 'GSI1PK', AttributeType: 'S' },
          { AttributeName: 'GSI1SK', AttributeType: 'S' },
        ],
        KeySchema: [
          { AttributeName: 'PK', KeyType: 'HASH' },
          { AttributeName: 'SK', KeyType: 'RANGE' },
        ],
        GlobalSecondaryIndexes: [
          {
            IndexName: 'user-index',
            KeySchema: [
              { AttributeName: 'GSI1PK', KeyType: 'HASH' },
              { AttributeName: 'GSI1SK', KeyType: 'RANGE' },
            ],
            Projection: { ProjectionType: 'ALL' },
          },
        ],
      }),
    );
    console.log(`✓ Table "${SUBSCRIPTIONS_TABLE_NAME}" created successfully.`);
  } else {
    console.log(`✓ Table "${SUBSCRIPTIONS_TABLE_NAME}" already exists — skipping.`);
  }

  if (!TableNames.includes(EVENTS_TABLE_NAME)) {
    await client.send(
      new CreateTableCommand({
        TableName: EVENTS_TABLE_NAME,
        BillingMode: 'PAY_PER_REQUEST',
        AttributeDefinitions: [
          { AttributeName: 'PK', AttributeType: 'S' },
          { AttributeName: 'SK', AttributeType: 'S' },
          { AttributeName: 'GSI1PK', AttributeType: 'S' },
          { AttributeName: 'GSI1SK', AttributeType: 'S' },
        ],
        KeySchema: [
          { AttributeName: 'PK', KeyType: 'HASH' },
          { AttributeName: 'SK', KeyType: 'RANGE' },
        ],
        GlobalSecondaryIndexes: [
          {
            IndexName: 'topic-index',
            KeySchema: [
              { AttributeName: 'GSI1PK', KeyType: 'HASH' },
              { AttributeName: 'GSI1SK', KeyType: 'RANGE' },
            ],
            Projection: { ProjectionType: 'ALL' },
          },
        ],
      }),
    );
    console.log(`✓ Table "${EVENTS_TABLE_NAME}" created successfully.`);
  } else {
    console.log(`✓ Table "${EVENTS_TABLE_NAME}" already exists — skipping.`);
  }
}

run().catch((err) => {
  console.error('Failed to create table:', err.message);
  process.exit(1);
});
