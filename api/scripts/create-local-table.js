'use strict';

/**
 * 로컬 DynamoDB에 topics/subscriptions 테이블을 생성하는 셋업 스크립트.
 * 실행: node scripts/create-local-table.js
 * 사전 조건: docker compose up -d 로 DynamoDB Local이 실행 중이어야 합니다.
 */

const { DynamoDBClient, CreateTableCommand, ListTablesCommand } = require('@aws-sdk/client-dynamodb');

const ENDPOINT = process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
const REGION = process.env.AWS_REGION || 'us-west-2';
const TOPICS_TABLE_NAME = process.env.TOPICS_TABLE || 't_topics-dev';
const SUBSCRIPTIONS_TABLE_NAME = process.env.SUBSCRIPTIONS_TABLE || 't_subscriptions';

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
          { AttributeName: 'topic_id', AttributeType: 'S' },
          { AttributeName: 'owner_id', AttributeType: 'S' },
          { AttributeName: 'created_at', AttributeType: 'S' },
        ],
        KeySchema: [{ AttributeName: 'topic_id', KeyType: 'HASH' }],
        GlobalSecondaryIndexes: [
          {
            IndexName: 'owner-index',
            KeySchema: [
              { AttributeName: 'owner_id', KeyType: 'HASH' },
              { AttributeName: 'created_at', KeyType: 'RANGE' },
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
          { AttributeName: 'pk', AttributeType: 'S' },
          { AttributeName: 'sk', AttributeType: 'S' },
        ],
        KeySchema: [
          { AttributeName: 'pk', KeyType: 'HASH' },
          { AttributeName: 'sk', KeyType: 'RANGE' },
        ],
      }),
    );
    console.log(`✓ Table "${SUBSCRIPTIONS_TABLE_NAME}" created successfully.`);
  } else {
    console.log(`✓ Table "${SUBSCRIPTIONS_TABLE_NAME}" already exists — skipping.`);
  }
}

run().catch((err) => {
  console.error('Failed to create table:', err.message);
  process.exit(1);
});
