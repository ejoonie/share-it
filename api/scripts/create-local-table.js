'use strict';

/**
 * 로컬 DynamoDB에 topics/subscriptions/events 테이블을 생성하는 셋업 스크립트.
 * 실행: node scripts/create-local-table.js
 * 사전 조건: docker compose up -d 로 DynamoDB Local이 실행 중이어야 합니다.
 */

const { DynamoDBClient, CreateTableCommand, ListTablesCommand } = require('@aws-sdk/client-dynamodb');
const tables = require('./dynamodb-tables.schema');

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
  // TopicsTable
  if (!TableNames.includes(tables.TopicsTable.TableName)) {
    await client.send(new CreateTableCommand(tables.TopicsTable));
    console.log(`✓ Table "${tables.TopicsTable.TableName}" created successfully.`);
  } else {
    console.log(`✓ Table "${tables.TopicsTable.TableName}" already exists — skipping.`);
  }
  // SubscriptionsTable
  if (!TableNames.includes(tables.SubscriptionsTable.TableName)) {
    await client.send(new CreateTableCommand(tables.SubscriptionsTable));
    console.log(`✓ Table "${tables.SubscriptionsTable.TableName}" created successfully.`);
  } else {
    console.log(`✓ Table "${tables.SubscriptionsTable.TableName}" already exists — skipping.`);
  }
  // EventsTable
  if (!TableNames.includes(tables.EventsTable.TableName)) {
    await client.send(new CreateTableCommand(tables.EventsTable));
    console.log(`✓ Table "${tables.EventsTable.TableName}" created successfully.`);
  } else {
    console.log(`✓ Table "${tables.EventsTable.TableName}" already exists — skipping.`);
  }
}

run().catch((err) => {
  console.error('Failed to create table:', err.message);
  process.exit(1);
});
