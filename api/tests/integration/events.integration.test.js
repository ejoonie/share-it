// events.integration.test.js
// 실제 DynamoDB를 사용하는 통합 테스트

'use strict';

const { v4: uuidv4 } = require('uuid');
const {
  putEvent,
  updateEventData,
  getEventByEntityId,
  queryEventsByTopic,
  setEventDeleted,
} = require('../../src/lib/dynamodb');

describe('events handlers (integration)', () => {
  let topicId, ownerId, entityId, eventId1, eventId2;

  beforeAll(async () => {
    topicId = `tp_${uuidv4()}`;
    ownerId = `u_${uuidv4()}`;
    // 최초 이벤트 생성
    const event = await putEvent({
      topicId,
      ownerId,
      updatedBy: ownerId,
      kind: 'expense',
      amount: 1000,
      category: 'food',
      content: '점심',
      checked: false,
      occurredAt: new Date().toISOString(),
    });
    entityId = event.entity_id;
    eventId1 = event.event_id;
  });

  it('POST /api/v1/topics/{topic_id}/events - 이벤트 생성: 실제로 이벤트가 생성되어야 한다', async () => {
    const events = await getEventByEntityId(entityId);
    expect(events.find(e => e.event_id === eventId1)).toBeDefined();
  });

  it('GET /api/v1/topics/{topic_id}/events - 토픽별 이벤트 목록 조회: 실제로 목록이 조회되어야 한다', async () => {
    const events = await queryEventsByTopic(topicId);
    expect(events.find(e => e.event_id === eventId1)).toBeDefined();
  });

  it('PATCH /api/v1/topics/{topic_id}/events/{event_id} - 이벤트 수정: append-only로 새로운 이벤트가 생성되어야 한다', async () => {
    const updated = await updateEventData(eventId1, ownerId, {
      amount: 2000,
      content: '저녁',
    });
    eventId2 = updated.event_id;
    expect(updated.entity_id).toBe(entityId);
    expect(updated.event_id).not.toBe(eventId1);
    // entity_id로 조회하면 두 이벤트 모두 나와야 함
    const events = await getEventByEntityId(entityId);
    const eventIds = events.map(e => e.event_id);
    expect(eventIds).toEqual(expect.arrayContaining([eventId1, eventId2]));
  });

  it('DELETE /api/v1/topics/{topic_id}/events/{event_id} - 이벤트 삭제(soft delete): deleted_at이 설정되어야 한다', async () => {
    const deleted = await setEventDeleted(eventId2);
    expect(deleted.deleted_at).toBeDefined();
    // entity_id로 조회하면 삭제된 이벤트도 포함
    const events = await getEventByEntityId(entityId);
    expect(events.find(e => e.event_id === eventId2 && e.deleted_at)).toBeDefined();
  });
});
