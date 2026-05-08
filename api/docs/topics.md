# Topic API 문서

share-it의 Topic API는 토픽(Topic) 생성·조회·수정·삭제 및 구독, 그리고 토픽에 속한 이벤트(Event)를 관리하는 엔드포인트를 제공합니다.

---

## 목차

1. [인증](#인증)
2. [공통 응답 코드](#공통-응답-코드)
3. [토픽 API](#토픽-api)
   - [토픽 생성](#1-토픽-생성)
   - [내 토픽 목록 조회](#2-내-토픽-목록-조회)
   - [토픽 제목 수정](#3-토픽-제목-수정)
   - [토픽 삭제](#4-토픽-삭제)
   - [기본 토픽 지정](#5-기본-토픽-지정)
   - [토픽 구독](#6-토픽-구독)
4. [이벤트 API](#이벤트-api)
   - [이벤트 생성](#1-이벤트-생성)
   - [토픽 이벤트 목록 조회](#2-토픽-이벤트-목록-조회)
   - [이벤트 수정](#3-이벤트-수정)
   - [이벤트 삭제](#4-이벤트-삭제)

---

## 인증

모든 API 요청에는 `x-user-id` 헤더가 필요합니다.

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 요청을 보내는 사용자 ID (예: `u_1`) |

헤더가 없으면 **401 Unauthorized** 응답이 반환됩니다.

---

## 공통 응답 코드

| 상태 코드 | 설명 |
|-----------|------|
| `200` | 요청 성공 |
| `201` | 리소스 생성 성공 |
| `400` | 잘못된 요청 (필수 파라미터 누락 등) |
| `401` | 인증 실패 (`x-user-id` 헤더 없음) |
| `403` | 권한 없음 (다른 사용자의 리소스 접근 시도) |
| `404` | 리소스를 찾을 수 없음 |
| `409` | 충돌 (이미 존재하는 구독 등) |
| `500` | 서버 내부 오류 |

---

## 토픽 API

### 1. 토픽 생성

새로운 토픽을 생성합니다.

- **메서드**: `POST`
- **경로**: `/api/v1/topics`

#### 요청

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |
| `content-type` | ✅ | `application/json` |

**바디**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | ✅ | 토픽 제목 (공백만으로는 불가) |

```json
{
  "title": "My Expenses"
}
```

#### 응답

**201 Created**

```json
{
  "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "owner_id": "u_1",
  "title": "My Expenses",
  "is_default": false,
  "last_sequence": 0,
  "created_at": "2026-01-01T00:00:00.000Z"
}
```

#### 예시

```bash
curl -X POST http://localhost:3001/api/v1/topics \
  -H "x-user-id: u_1" \
  -H "content-type: application/json" \
  -d '{"title": "My Expenses"}'
```

---

### 2. 내 토픽 목록 조회

현재 사용자가 소유한 토픽 목록을 반환합니다.

- **메서드**: `GET`
- **경로**: `/api/v1/topics/owned`

#### 요청

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |

#### 응답

**200 OK**

```json
{
  "topics": [
    {
      "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "owner_id": "u_1",
      "title": "My Expenses",
      "is_default": false,
      "last_sequence": 0,
      "created_at": "2026-01-01T00:00:00.000Z",
      "updated_at": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

#### 예시

```bash
curl http://localhost:3001/api/v1/topics/owned \
  -H "x-user-id: u_1"
```

---

### 3. 토픽 제목 수정

특정 토픽의 제목을 수정합니다. 토픽의 소유자만 수정할 수 있습니다.

- **메서드**: `PATCH`
- **경로**: `/api/v1/topics/{topic_id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 수정할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |
| `content-type` | ✅ | `application/json` |

**바디**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | ✅ | 변경할 토픽 제목 |

```json
{
  "title": "Updated Title"
}
```

#### 응답

**200 OK**

```json
{
  "topic": {
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "owner_id": "u_1",
    "title": "Updated Title",
    "is_default": false,
    "last_sequence": 0,
    "created_at": "2026-01-01T00:00:00.000Z",
    "updated_at": "2026-01-02T00:00:00.000Z"
  }
}
```

#### 예시

```bash
curl -X PATCH http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  -H "x-user-id: u_1" \
  -H "content-type: application/json" \
  -d '{"title": "Updated Title"}'
```

---

### 4. 토픽 삭제

특정 토픽을 soft delete 처리합니다 (`deleted_at` 필드가 설정됩니다). 토픽의 소유자만 삭제할 수 있습니다.

- **메서드**: `DELETE`
- **경로**: `/api/v1/topics/{topic_id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 삭제할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |

#### 응답

**200 OK**

```json
{
  "topic": {
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "owner_id": "u_1",
    "title": "My Expenses",
    "is_default": false,
    "last_sequence": 0,
    "created_at": "2026-01-01T00:00:00.000Z",
    "updated_at": "2026-01-02T00:00:00.000Z",
    "deleted_at": "2026-01-02T00:00:00.000Z"
  }
}
```

#### 예시

```bash
curl -X DELETE http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  -H "x-user-id: u_1"
```

---

### 5. 기본 토픽 지정

특정 토픽을 기본 토픽으로 지정합니다. 한 사용자당 하나의 토픽만 기본 토픽(`is_default: true`)으로 설정될 수 있으며, 기존 기본 토픽은 자동으로 해제됩니다. 토픽의 소유자만 설정할 수 있습니다.

- **메서드**: `POST`
- **경로**: `/api/v1/topics/{topic_id}/default`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 기본 토픽으로 지정할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |

#### 응답

**200 OK**

```json
{
  "topic": {
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "owner_id": "u_1",
    "title": "My Expenses",
    "is_default": true,
    "last_sequence": 0,
    "created_at": "2026-01-01T00:00:00.000Z",
    "updated_at": "2026-01-02T00:00:00.000Z"
  }
}
```

#### 예시

```bash
curl -X POST http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/default \
  -H "x-user-id: u_1"
```

---

### 6. 토픽 구독

특정 토픽을 구독합니다. 이미 구독 중인 경우 409가 반환됩니다.

- **메서드**: `POST`
- **경로**: `/api/v1/topics/{topic_id}/subscribe`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 구독할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |

#### 응답

**201 Created**

```json
{
  "subscription": {
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "user_id": "u_2",
    "created_at": "2026-01-01T00:00:00.000Z"
  }
}
```

**409 Conflict** — 이미 구독 중인 경우

```json
{
  "message": "Already subscribed"
}
```

#### 예시

```bash
curl -X POST http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/subscribe \
  -H "x-user-id: u_2"
```

---

## 이벤트 API

토픽에 속하는 이벤트(Event)를 생성·조회·수정·삭제하는 API입니다.

### 1. 이벤트 생성

특정 토픽에 새로운 이벤트를 생성합니다. 토픽의 소유자(`x-user-id`)가 존재해야 하며, 이미 삭제된 토픽에는 이벤트를 추가할 수 없습니다.

- **메서드**: `POST`
- **경로**: `/api/v1/topics/{topic_id}/events`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 이벤트를 추가할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |
| `content-type` | ✅ | `application/json` |

**바디**

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `sequence` | number | ❌ | 이벤트 순서 (기본값: `0`) |
| `kind` | string | ❌ | 이벤트 종류 (기본값: `null`) |
| `amount` | number | ❌ | 금액 (기본값: `null`) |
| `category` | string | ❌ | 카테고리 (기본값: `null`) |
| `content` | string | ❌ | 이벤트 내용 (기본값: `null`) |
| `checked` | boolean | ❌ | 확인 여부 (기본값: `false`) |
| `occurred_at` | string (ISO 8601) | ❌ | 이벤트 발생 시각 (기본값: 현재 시각) |

```json
{
  "kind": "expense",
  "amount": 15000,
  "category": "food",
  "content": "점심 식사",
  "checked": false,
  "occurred_at": "2026-01-01T12:00:00.000Z"
}
```

#### 응답

**201 Created**

```json
{
  "event": {
    "event_id": "ev_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "owner_id": "u_1",
    "updated_by": "u_1",
    "sequence": 0,
    "kind": "expense",
    "amount": 15000,
    "category": "food",
    "content": "점심 식사",
    "checked": false,
    "occurred_at": "2026-01-01T12:00:00.000Z",
    "created_at": "2026-01-01T12:00:00.000Z",
    "updated_at": "2026-01-01T12:00:00.000Z"
  }
}
```

#### 예시

```bash
curl -X POST http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/events \
  -H "x-user-id: u_1" \
  -H "content-type: application/json" \
  -d '{"kind": "expense", "amount": 15000, "category": "food", "content": "점심 식사"}'
```

---

### 2. 토픽 이벤트 목록 조회

특정 토픽에 속한 이벤트 목록을 반환합니다.

- **메서드**: `GET`
- **경로**: `/api/v1/topics/{topic_id}/events`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 조회할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |

#### 응답

**200 OK**

```json
{
  "events": [
    {
      "event_id": "ev_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "owner_id": "u_1",
      "updated_by": "u_1",
      "sequence": 0,
      "kind": "expense",
      "amount": 15000,
      "category": "food",
      "content": "점심 식사",
      "checked": false,
      "occurred_at": "2026-01-01T12:00:00.000Z",
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z"
    }
  ]
}
```

#### 예시

```bash
curl http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/events \
  -H "x-user-id: u_1"
```

---

### 3. 이벤트 수정

특정 이벤트의 데이터를 수정합니다.

- **메서드**: `PATCH`
- **경로**: `/api/v1/topics/{topic_id}/events/{event_id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `event_id` | ✅ | 수정할 이벤트 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |
| `content-type` | ✅ | `application/json` |

**바디**

수정할 필드만 포함하면 됩니다.

| 필드 | 타입 | 설명 |
|------|------|------|
| `kind` | string | 이벤트 종류 |
| `amount` | number | 금액 |
| `category` | string | 카테고리 |
| `content` | string | 이벤트 내용 |
| `checked` | boolean | 확인 여부 |
| `occurred_at` | string (ISO 8601) | 이벤트 발생 시각 |

```json
{
  "amount": 20000,
  "checked": true
}
```

#### 응답

**200 OK**

```json
{
  "event": {
    "event_id": "ev_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "owner_id": "u_1",
    "updated_by": "u_1",
    "sequence": 0,
    "kind": "expense",
    "amount": 20000,
    "category": "food",
    "content": "점심 식사",
    "checked": true,
    "occurred_at": "2026-01-01T12:00:00.000Z",
    "created_at": "2026-01-01T12:00:00.000Z",
    "updated_at": "2026-01-02T09:00:00.000Z"
  }
}
```

#### 예시

```bash
curl -X PATCH http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/events/ev_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  -H "x-user-id: u_1" \
  -H "content-type: application/json" \
  -d '{"amount": 20000, "checked": true}'
```

---

### 4. 이벤트 삭제

특정 이벤트를 soft delete 처리합니다 (`deleted_at` 필드가 설정됩니다).

- **메서드**: `DELETE`
- **경로**: `/api/v1/topics/{topic_id}/events/{event_id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `event_id` | ✅ | 삭제할 이벤트 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-user-id` | ✅ | 사용자 ID |

#### 응답

**200 OK**

```json
{
  "event": {
    "event_id": "ev_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "topic_id": "tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "owner_id": "u_1",
    "updated_by": "u_1",
    "sequence": 0,
    "kind": "expense",
    "amount": 15000,
    "category": "food",
    "content": "점심 식사",
    "checked": false,
    "occurred_at": "2026-01-01T12:00:00.000Z",
    "created_at": "2026-01-01T12:00:00.000Z",
    "updated_at": "2026-01-02T09:00:00.000Z",
    "deleted_at": "2026-01-02T09:00:00.000Z"
  }
}
```

#### 예시

```bash
curl -X DELETE http://localhost:3001/api/v1/topics/tp_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/events/ev_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  -H "x-user-id: u_1"
```

---

## API 엔드포인트 요약

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `POST` | `/api/v1/topics` | 토픽 생성 |
| `GET` | `/api/v1/topics/owned` | 내 토픽 목록 조회 |
| `PATCH` | `/api/v1/topics/{topic_id}` | 토픽 제목 수정 |
| `DELETE` | `/api/v1/topics/{topic_id}` | 토픽 삭제 (soft delete) |
| `POST` | `/api/v1/topics/{topic_id}/default` | 기본 토픽 지정 |
| `POST` | `/api/v1/topics/{topic_id}/subscribe` | 토픽 구독 |
| `POST` | `/api/v1/topics/{topic_id}/events` | 이벤트 생성 |
| `GET` | `/api/v1/topics/{topic_id}/events` | 토픽 이벤트 목록 조회 |
| `PATCH` | `/api/v1/topics/{topic_id}/events/{event_id}` | 이벤트 수정 |
| `DELETE` | `/api/v1/topics/{topic_id}/events/{event_id}` | 이벤트 삭제 (soft delete) |
