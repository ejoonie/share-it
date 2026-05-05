import type { APIGatewayProxyEvent } from 'aws-lambda';
import {
  createEvent,
  getTopicEvents,
  updateEvent,
  deleteEvent,
} from '../../src/handlers/events';

jest.mock('../../src/lib/dynamodb', () => ({
  getTopicById: jest.fn(),
  putEvent: jest.fn(),
  queryEventsByTopic: jest.fn(),
  getEventById: jest.fn(),
  updateEventData: jest.fn(),
  setEventDeleted: jest.fn(),
}));

import {
  getTopicById,
  putEvent,
  queryEventsByTopic,
  getEventById,
  updateEventData,
  setEventDeleted,
} from '../../src/lib/dynamodb';

const mockedGetTopicById = getTopicById as jest.MockedFunction<typeof getTopicById>;
const mockedPutEvent = putEvent as jest.MockedFunction<typeof putEvent>;
const mockedQueryEventsByTopic = queryEventsByTopic as jest.MockedFunction<typeof queryEventsByTopic>;
const mockedGetEventById = getEventById as jest.MockedFunction<typeof getEventById>;
const mockedUpdateEventData = updateEventData as jest.MockedFunction<typeof updateEventData>;
const mockedSetEventDeleted = setEventDeleted as jest.MockedFunction<typeof setEventDeleted>;

function makeEvent(overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent {
  return {
    headers: {},
    body: null,
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    multiValueHeaders: {},
    httpMethod: 'GET',
    isBase64Encoded: false,
    path: '/',
    resource: '/',
    stageVariables: null,
    requestContext: {} as APIGatewayProxyEvent['requestContext'],
    ...overrides,
  };
}

function makeEventItem(overrides: Record<string, unknown> = {}) {
  return {
    PK: 'TOPIC#tp_1',
    SK: 'SEQ#000000000001',
    GSI1PK: 'EVENT#ev_1',
    GSI1SK: 'EVENT',
    GSI2PK: 'ENTITY#ent_1',
    GSI2SK: 'ENTITY',
    GSI3PK: 'TOPIC#tp_1',
    GSI3SK: 'OCCURRED_AT#2026-01-01T00:00:00.000Z#EVENT#ev_1',
    entity_id: 'ent_1',
    event_id: 'ev_1',
    topic_id: 'tp_1',
    owner_id: 'u_owner',
    updated_by: 'u_1',
    sequence: 1,
    kind: null,
    amount: null,
    category: null,
    content: null,
    checked: false,
    occurred_at: '2026-01-01T00:00:00.000Z',
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    deleted_at: null,
    ...overrides,
  };
}

describe('events handlers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('POST /api/v1/topics/{topic_id}/events - 이벤트 생성: createEvent should create event and return 201', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: 'tp_1',
      owner_id: 'u_owner',
      PK: 'TOPIC#tp_1',
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_owner',
      GSI1SK: 'TOPIC#2026-01-01T00:00:00.000Z#tp_1',
      title: 'test',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedPutEvent.mockResolvedValue(makeEventItem({ owner_id: 'u_owner' }) as ReturnType<typeof makeEventItem> & { deleted_at: null });

    const result = await createEvent(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: 'tp_1' },
        body: JSON.stringify({ title: 'groceries', amount: 1200 }),
      }),
    );

    expect(result.statusCode).toBe(201);
    expect(mockedPutEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        topicId: 'tp_1',
        ownerId: 'u_owner',
        updatedBy: 'u_1',
        amount: 1200,
        content: null,
        category: null,
        checked: false,
        occurredAt: expect.any(String),
      }),
    );
  });

  it('GET /api/v1/topics/{topic_id}/events - 토픽별 이벤트 목록 조회: getTopicEvents should return topic events', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: 'tp_1',
      owner_id: 'u_owner',
      PK: 'TOPIC#tp_1',
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_owner',
      GSI1SK: 'TOPIC#2026-01-01T00:00:00.000Z#tp_1',
      title: 'test',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedQueryEventsByTopic.mockResolvedValue([makeEventItem() as ReturnType<typeof makeEventItem> & { deleted_at: null }]);

    const result = await getTopicEvents(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: 'tp_1' },
      }),
    );

    expect(result.statusCode).toBe(200);
    expect(mockedQueryEventsByTopic).toHaveBeenCalledWith('tp_1');
  });

  it('PATCH /api/v1/topics/{topic_id}/events/{event_id} - 이벤트 수정: updateEvent should update existing event', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: 'tp_1',
      owner_id: 'u_owner',
      PK: 'TOPIC#tp_1',
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_owner',
      GSI1SK: 'TOPIC#2026-01-01T00:00:00.000Z#tp_1',
      title: 'test',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedGetEventById.mockResolvedValue(makeEventItem() as ReturnType<typeof makeEventItem> & { deleted_at: null });
    mockedUpdateEventData.mockResolvedValue(makeEventItem() as ReturnType<typeof makeEventItem> & { deleted_at: null });

    const result = await updateEvent(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: 'tp_1', event_id: 'ev_1' },
        body: JSON.stringify({ title: 'updated' }),
      }),
    );

    expect(result.statusCode).toBe(200);
    expect(mockedUpdateEventData).toHaveBeenCalledWith('ev_1', 'u_1', { title: 'updated' });
  });

  it('DELETE /api/v1/topics/{topic_id}/events/{event_id} - 이벤트 삭제(soft delete): deleteEvent should soft-delete existing event', async () => {
    mockedGetTopicById.mockResolvedValue({
      topic_id: 'tp_1',
      owner_id: 'u_owner',
      PK: 'TOPIC#tp_1',
      SK: 'TOPIC',
      GSI1PK: 'OWNER#u_owner',
      GSI1SK: 'TOPIC#2026-01-01T00:00:00.000Z#tp_1',
      title: 'test',
      is_default: false,
      last_sequence: 0,
      created_at: '2026-01-01T00:00:00.000Z',
      updated_at: '2026-01-01T00:00:00.000Z',
    });
    mockedGetEventById.mockResolvedValue(makeEventItem() as ReturnType<typeof makeEventItem> & { deleted_at: null });
    mockedSetEventDeleted.mockResolvedValue(
      makeEventItem({ deleted_at: '2026-01-01T00:00:00.000Z' }) as ReturnType<typeof makeEventItem> & { deleted_at: string },
    );

    const result = await deleteEvent(
      makeEvent({
        headers: { 'x-user-id': 'u_1' },
        pathParameters: { topic_id: 'tp_1', event_id: 'ev_1' },
      }),
    );

    expect(result.statusCode).toBe(200);
    expect(mockedSetEventDeleted).toHaveBeenCalledWith('ent_1'); // entity_id from the mock event
  });
});
