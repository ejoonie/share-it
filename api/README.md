# share-it API

Node.js Lambda 함수 + API Gateway (HTTP API) + DynamoDB로 구성된 topics CRUD API입니다.

---

## 사전 요구사항

| 도구 | 버전 | 용도 |
|------|------|------|
| Node.js | 20.x 이상 | Lambda 런타임과 동일 버전 |
| Docker | 최신 | DynamoDB Local 실행 |

---

## 로컬 실행

### 1단계 — 의존성 설치

```bash
cd api
yarn install
```

### 2단계 — 환경 변수 설정

```bash
cp .env.example .env
```

`.env` 파일은 아래 내용을 기본으로 포함합니다:

```env
AWS_REGION=us-west-2
TOPICS_TABLE=t_topics-dev
DYNAMODB_ENDPOINT=http://localhost:8000
```

### 3단계 — DynamoDB Local 시작

```bash
docker compose up -d
```

컨테이너가 정상적으로 뜨면 `http://localhost:8000` 에서 DynamoDB Local이 실행됩니다.

### 4단계 — 테이블 생성

```bash
yarn run db:setup
```

`t_topics-dev` 테이블과 `owner-index` GSI가 생성됩니다.  
(이미 존재하면 건너뜁니다.)

### 5단계 — API 서버 시작

```bash
yarn run dev
```

`serverless-offline`이 실행되며 `http://localhost:3001` 에서 API를 사용할 수 있습니다.

---

## API 엔드포인트

### 토픽 생성

```bash
curl -X POST http://localhost:3001/api/v1/topics \
  -H "x-user-id: u_1" \
  -H "content-type: application/json" \
  -d '{"title": "My Expenses"}'
```

**응답 (201)**

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

### 내 토픽 목록 조회

```bash
curl http://localhost:3001/api/v1/topics/owned \
  -H "x-user-id: u_1"
```

**응답 (200)**

```json
{
  "topics": [
    {
      "topic_id": "tp_...",
      "owner_id": "u_1",
      "title": "My Expenses",
      "last_sequence": 0,
      "created_at": "2026-01-01T00:00:00.000Z",
      "updated_at": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

---

## 테스트

```bash
yarn test          # 전체 테스트 + 커버리지
yarn run test:unit # 유닛 테스트만
```

---

## 추가 엔드포인트

- `PATCH /api/v1/topics/{topic_id}`: 토픽 제목 수정
- `DELETE /api/v1/topics/{topic_id}`: 토픽 soft delete (`deleted_at` 설정)
- `POST /api/v1/topics/{topic_id}/default`: 기본 토픽 지정 (한 번에 하나만 `is_default=true`)
- `POST /api/v1/topics/{topic_id}/subscribe`: 토픽 구독 (`t_subscriptions`, `pk=TOPIC#{topic_id}`)

---

## 배포

```bash
yarn run deploy:dev   # → t_topics-dev (development stage)
yarn run deploy:prod  # → t_topics-prod (production stage)
```

> AWS 자격증명이 설정되어 있어야 합니다 (`aws configure` 또는 환경 변수).

---

## 스테이지 / 테이블 대응

| 스테이지 | DynamoDB 테이블 |
|----------|----------------|
| `dev`    | `t_topics-dev` |
| `prod`   | `t_topics-prod` |
| `test`   | `t_topics-test` |
