'use strict';

/**
 * 로컬 DynamoDB에 t_topics-dev 테이블 및 GSI를 생성하는 셋업 스크립트.
 * 실행: node scripts/create-local-table.js
 * 사전 조건: docker compose up -d 로 DynamoDB Local이 실행 중이어야 합니다.
 */

const { DynamoDBClient, CreateTableCommand, ListTablesCommand } = require('@aws-sdk/client-dynamodb');

const ENDPOINT = process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
const REGION = process.env.AWS_REGION || 'us-west-2';
const TABLE_NAME = process.env.TOPICS_TABLE || 't_topics-dev';

const client = new DynamoDBClient({
  region: REGION,
  endpoint: ENDPOINT,
  credentials: { accessKeyId: 'local', secretAccessKey: 'local' }, // 로컬 전용 더미 자격증명
});

async function run() {
  // 이미 테이블이 있으면 건너뜀
  const { TableNames } = await client.send(new ListTablesCommand({}));
  if (TableNames.includes(TABLE_NAME)) {
    console.log(`✓ Table "${TABLE_NAME}" already exists — skipping.`);
    return;
  }

  await client.send(
    new CreateTableCommand({
      TableName: TABLE_NAME,
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

  console.log(`✓ Table "${TABLE_NAME}" created successfully.`);
}

run().catch((err) => {
  console.error('Failed to create table:', err.message);
  process.exit(1);
});
