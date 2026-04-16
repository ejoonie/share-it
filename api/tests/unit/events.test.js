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
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('createEvent should create event and return 201', async () => {
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

  it('getTopicEvents should return topic events', async () => {
    getTopicById.mockResolvedValue({ topic_id: 'tp_1' });
    queryEventsByTopic.mockResolvedValue([{ event_id: 'ev_1', topic_id: 'tp_1' }]);

    const result = await getTopicEvents({
      headers: { 'x-user-id': 'u_1' },
      pathParameters: { topic_id: 'tp_1' },
    });

    expect(result.statusCode).toBe(200);
    expect(queryEventsByTopic).toHaveBeenCalledWith('tp_1');
  });

  it('updateEvent should update existing event', async () => {
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

  it('deleteEvent should soft-delete existing event', async () => {
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
