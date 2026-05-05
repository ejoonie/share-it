'use strict';

const {
  createEvent,
  getTopicEvents,
  updateEvent,
  deleteEvent,
} = require('../../src/handlers/events');

jest.mock('../../src/lib/dynamodb', () => ({
  getTopicById: jest.fn(),
  putEvent: jest.fn(),
  queryEventsByTopic: jest.fn(),
  getEventById: jest.fn(),
  updateEventData: jest.fn(),
  setEventDeleted: jest.fn(),
}));

const {
  getTopicById,
  putEvent,
  queryEventsByTopic,
  getEventById,
  updateEventData,
  setEventDeleted,
} = require('../../src/lib/dynamodb');

describe('events handlers', () => {
  const { v4: uuidv4 } = require('uuid');
  const {
    putEvent,
    updateEventData,
    getEventByEntityId,
    queryEventsByTopic,
    setEventDeleted,
  } = require('../../src/lib/dynamodb');

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('POST /api/v1/topics/{topic_id}/events - 이벤트 생성: createEvent should create event and return 201', async () => {
    getTopicById.mockResolvedValue({ topic_id: 'tp_1', owner_id: 'u_owner' });
    putEvent.mockResolvedValue({ event_id: 'ev_1', topic_id: 'tp_1', owner_id: 'u_owner' });

    const result = await createEvent({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: 'tp_1' },
      body: JSON.stringify({ title: 'groceries', amount: 1200 }),
    });

    expect(result.statusCode).toBe(201);
    expect(putEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventId: expect.stringMatching(/^ev_/),
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
    getTopicById.mockResolvedValue({ topic_id: 'tp_1' });
    queryEventsByTopic.mockResolvedValue([{ event_id: 'ev_1', topic_id: 'tp_1' }]);

    const result = await getTopicEvents({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: 'tp_1' },
    });

    expect(result.statusCode).toBe(200);
    expect(queryEventsByTopic).toHaveBeenCalledWith('tp_1');
  });

  it('PATCH /api/v1/topics/{topic_id}/events/{event_id} - 이벤트 수정: updateEvent should update existing event', async () => {
    getTopicById.mockResolvedValue({ topic_id: 'tp_1' });
    getEventById.mockResolvedValue({ event_id: 'ev_1', topic_id: 'tp_1' });
    updateEventData.mockResolvedValue({ event_id: 'ev_1', topic_id: 'tp_1' });

    const result = await updateEvent({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: 'tp_1', event_id: 'ev_1' },
      body: JSON.stringify({ title: 'updated' }),
    });

    expect(result.statusCode).toBe(200);
    expect(updateEventData).toHaveBeenCalledWith('ev_1', 'u_1', { title: 'updated' });
  });

  it('DELETE /api/v1/topics/{topic_id}/events/{event_id} - 이벤트 삭제(soft delete): deleteEvent should soft-delete existing event', async () => {
    getTopicById.mockResolvedValue({ topic_id: 'tp_1' });
    getEventById.mockResolvedValue({ event_id: 'ev_1', topic_id: 'tp_1' });
    setEventDeleted.mockResolvedValue({ event_id: 'ev_1', deleted_at: '2026-01-01T00:00:00.000Z' });

    const result = await deleteEvent({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: 'tp_1', event_id: 'ev_1' },
    });

    expect(result.statusCode).toBe(200);
    expect(setEventDeleted).toHaveBeenCalledWith('ev_1');
  });
});
