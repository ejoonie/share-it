# Entry API 문서

share-it의 Entry API는 토픽(Topic)에 속한 항목(Entry)을 생성·조회·수정·삭제하는 엔드포인트를 제공합니다.

---

## 목차

1. [인증](#인증)
2. [공통 응답 코드](#공통-응답-코드)
3. [엔트리 필드](#엔트리-필드)
4. [엔트리 API](#엔트리-api)
   - [엔트리 생성](#1-엔트리-생성)
   - [엔트리 목록 조회](#2-엔트리-목록-조회)
   - [엔트리 단건 조회](#3-엔트리-단건-조회)
   - [엔트리 수정](#4-엔트리-수정)
   - [엔트리 삭제](#5-엔트리-삭제)
5. [검색(Ransack) 쿼리 가이드](#검색ransack-쿼리-가이드)
6. [Flutter 사용 예제](#flutter-사용-예제)

---

## 인증

모든 API 요청에는 `x-token` 헤더가 필요합니다.

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 인증 토큰 (User.token 값) |
| `content-type` | ✅ (바디 있는 경우) | `application/json` |

헤더가 없으면 **401 Unauthorized** 응답이 반환됩니다.

---

## 공통 응답 코드

| 상태 코드 | 설명 |
|-----------|------|
| `200` | 요청 성공 |
| `201` | 리소스 생성 성공 |
| `400` | 잘못된 요청 (필수 파라미터 누락 등) |
| `401` | 인증 실패 (`x-token` 헤더 없음 또는 유효하지 않음) |
| `404` | 리소스를 찾을 수 없음 (토픽 또는 엔트리 없음) |
| `500` | 서버 내부 오류 |

---

## 엔트리 필드

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `id` | integer | — | — | 엔트리 고유 ID |
| `topic_id` | integer | — | — | 소속 토픽 ID |
| `created_by_id` | integer | — | — | 생성한 사용자 ID |
| `updated_by_id` | integer | — | — | 마지막으로 수정한 사용자 ID |
| `occurred_at` | datetime (ISO 8601) | ❌ | `null` | 항목 발생 시각 |
| `kind` | string | ❌ | `null` | 항목 종류 (예: `"expense"`, `"income"`) |
| `currency` | string | ❌ | `"usd"` | 통화 코드 (예: `"krw"`, `"usd"`) |
| `amount` | integer | ❌ | `0` | 금액 |
| `category` | string | ❌ | `null` | 카테고리 (예: `"food"`, `"transport"`) |
| `title` | string | ❌ | `null` | 항목 제목 |
| `content` | string | ❌ | `null` | 항목 내용 |
| `checked` | boolean | ❌ | `false` | 확인 여부 |
| `deleted_at` | datetime | — | `null` | soft delete 시각 (null이면 활성 상태) |
| `created_at` | datetime | — | — | 생성 시각 |
| `updated_at` | datetime | — | — | 마지막 수정 시각 |

---

## 엔트리 API

모든 엔드포인트는 `/api/v1/my/topics/:topic_id/entries` 하위에 있습니다.
`topic_id`는 엔트리를 관리할 토픽의 숫자 ID입니다.

---

### 1. 엔트리 생성

새로운 엔트리를 생성합니다. `created_by`와 `updated_by`는 인증된 사용자로 자동 설정됩니다.

- **메서드**: `POST`
- **경로**: `/api/v1/my/topics/{topic_id}/entries`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 엔트리를 추가할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |
| `content-type` | ✅ | `application/json` |

**바디** (모든 필드 선택)

```json
{
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false
}
```

#### 응답

**201 Created**

```json
{
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 7,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-01T12:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl -X POST https://api.example.com/api/v1/my/topics/42/entries \
  -H "x-token: YOUR_TOKEN" \
  -H "content-type: application/json" \
  -d '{"kind": "expense", "currency": "krw", "amount": 15000, "category": "food", "title": "점심"}'
```

---

### 2. 엔트리 목록 조회

토픽에 속한 엔트리를 반환합니다. soft delete된 항목은 제외됩니다.  
기본 정렬은 최신순(`created_at DESC`)이며, `q[s]` 파라미터로 변경할 수 있습니다.  
`q` 파라미터를 사용하여 [Ransack](#검색ransack-쿼리-가이드) 조건으로 필터링·정렬이 가능합니다.

- **메서드**: `GET`
- **경로**: `/api/v1/my/topics/{topic_id}/entries`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 조회할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |

**쿼리 파라미터 (`q`)**

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `q[kind_eq]` | string | kind가 정확히 일치하는 항목 |
| `q[currency_eq]` | string | currency가 정확히 일치하는 항목 |
| `q[amount_eq]` | integer | amount가 정확히 일치하는 항목 |
| `q[amount_gteq]` | integer | amount가 이 값 이상인 항목 |
| `q[amount_lteq]` | integer | amount가 이 값 이하인 항목 |
| `q[category_eq]` | string | category가 정확히 일치하는 항목 |
| `q[title_cont]` | string | title에 해당 문자열이 포함된 항목 |
| `q[content_cont]` | string | content에 해당 문자열이 포함된 항목 |
| `q[checked_eq]` | boolean | checked 상태가 일치하는 항목 |
| `q[occurred_at_gteq]` | datetime | occurred_at이 이 값 이상인 항목 |
| `q[occurred_at_lteq]` | datetime | occurred_at이 이 값 이하인 항목 |
| `q[created_at_gteq]` | datetime | created_at이 이 값 이상인 항목 |
| `q[created_at_lteq]` | datetime | created_at이 이 값 이하인 항목 |
| `q[s]` | string | 정렬 기준 (예: `amount asc`, `occurred_at desc`) |

#### 응답

**200 OK**

```json
{
  "total": 2,
  "records": [
    {
      "id": 2,
      "topic_id": 42,
      "created_by_id": 7,
      "updated_by_id": 7,
      "occurred_at": "2026-01-02T09:00:00.000Z",
      "kind": "income",
      "currency": "krw",
      "amount": 50000,
      "category": "salary",
      "title": null,
      "content": null,
      "checked": false,
      "deleted_at": null,
      "created_at": "2026-01-02T09:00:00.000Z",
      "updated_at": "2026-01-02T09:00:00.000Z"
    },
    {
      "id": 1,
      "topic_id": 42,
      "created_by_id": 7,
      "updated_by_id": 7,
      "occurred_at": "2026-01-01T12:00:00.000Z",
      "kind": "expense",
      "currency": "krw",
      "amount": 15000,
      "category": "food",
      "title": "점심",
      "content": "팀 점심 식사",
      "checked": false,
      "deleted_at": null,
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z"
    }
  ]
}
```

#### 예시 (curl)

```bash
curl https://api.example.com/api/v1/my/topics/42/entries \
  -H "x-token: YOUR_TOKEN"
```

---

### 3. 엔트리 단건 조회

특정 엔트리를 조회합니다.

- **메서드**: `GET`
- **경로**: `/api/v1/my/topics/{topic_id}/entries/{id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `id` | ✅ | 엔트리 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |

#### 응답

**200 OK**

```json
{
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 7,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-01T12:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl https://api.example.com/api/v1/my/topics/42/entries/1 \
  -H "x-token: YOUR_TOKEN"
```

---

### 4. 엔트리 수정

엔트리를 수정합니다. 수정 시 `updated_by`는 현재 인증된 사용자로 자동 갱신됩니다.
수정할 필드만 포함하면 됩니다.

- **메서드**: `PATCH`
- **경로**: `/api/v1/my/topics/{topic_id}/entries/{id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `id` | ✅ | 수정할 엔트리 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |
| `content-type` | ✅ | `application/json` |

**바디** (수정할 필드만 포함)

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
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 8,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 20000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": true,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-02T09:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl -X PATCH https://api.example.com/api/v1/my/topics/42/entries/1 \
  -H "x-token: YOUR_TOKEN" \
  -H "content-type: application/json" \
  -d '{"amount": 20000, "checked": true}'
```

---

### 5. 엔트리 삭제

엔트리를 soft delete 처리합니다 (`deleted_at` 필드가 설정됩니다). 삭제된 엔트리는 목록 조회 시 제외됩니다.

- **메서드**: `DELETE`
- **경로**: `/api/v1/my/topics/{topic_id}/entries/{id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `id` | ✅ | 삭제할 엔트리 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |

#### 응답

**200 OK** — 삭제된 엔트리 반환

```json
{
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 7,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false,
  "deleted_at": "2026-01-02T09:00:00.000Z",
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-02T09:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl -X DELETE https://api.example.com/api/v1/my/topics/42/entries/1 \
  -H "x-token: YOUR_TOKEN"
```

---

## 검색(Ransack) 쿼리 가이드

엔트리 목록 조회(`GET /api/v1/my/topics/{topic_id}/entries`) 엔드포인트는 [Ransack](https://github.com/activerecord-hackery/ransack) 기반의 유연한 검색·정렬을 지원합니다.  
`q[<필드>_<조건>]=<값>` 형식의 쿼리 파라미터로 다양한 필터를 조합할 수 있습니다.

### 지원 조건(Predicate) 목록

| 조건 | 설명 | 예시 |
|------|------|------|
| `_eq` | 정확히 일치 | `q[kind_eq]=expense` |
| `_cont` | 포함 (LIKE %값%) | `q[title_cont]=점심` |
| `_gteq` | 이상 (>=) | `q[amount_gteq]=10000` |
| `_lteq` | 이하 (<=) | `q[amount_lteq]=50000` |
| `s` | 정렬 (필드 + 방향) | `q[s]=amount+asc` |

### 샘플 쿼리

#### 1. kind가 "expense"인 항목 조회

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[kind_eq]=expense" \
  -H "x-token: YOUR_TOKEN"
```

#### 2. title에 "점심"이 포함된 항목 조회

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[title_cont]=점심" \
  -H "x-token: YOUR_TOKEN"
```

#### 3. amount가 10,000 이상 50,000 이하인 항목 조회

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[amount_gteq]=10000&q[amount_lteq]=50000" \
  -H "x-token: YOUR_TOKEN"
```

#### 4. category가 "food"이고 checked가 false인 항목 조회

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[category_eq]=food&q[checked_eq]=false" \
  -H "x-token: YOUR_TOKEN"
```

#### 5. 특정 날짜 범위 내의 항목 조회

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[occurred_at_gteq]=2026-01-01T00:00:00Z&q[occurred_at_lteq]=2026-01-31T23:59:59Z" \
  -H "x-token: YOUR_TOKEN"
```

#### 6. amount 오름차순 정렬

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[s]=amount+asc" \
  -H "x-token: YOUR_TOKEN"
```

#### 7. occurred_at 내림차순 정렬

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[s]=occurred_at+desc" \
  -H "x-token: YOUR_TOKEN"
```

#### 8. 복합 조건: kind="income"이고 amount 내림차순 정렬

```bash
curl "https://api.example.com/api/v1/my/topics/42/entries?q[kind_eq]=income&q[s]=amount+desc" \
  -H "x-token: YOUR_TOKEN"
```

### Flutter 검색 예제

```dart
Future<Map<String, dynamic>> searchEntries({
  required int topicId,
  String? kindEq,
  String? titleCont,
  int? amountGteq,
  int? amountLteq,
  bool? checkedEq,
  DateTime? occurredAtGteq,
  DateTime? occurredAtLteq,
  String? sortBy,
}) async {
  final query = <String, String>{};
  if (kindEq != null) query['q[kind_eq]'] = kindEq;
  if (titleCont != null) query['q[title_cont]'] = titleCont;
  if (amountGteq != null) query['q[amount_gteq]'] = amountGteq.toString();
  if (amountLteq != null) query['q[amount_lteq]'] = amountLteq.toString();
  if (checkedEq != null) query['q[checked_eq]'] = checkedEq.toString();
  if (occurredAtGteq != null) query['q[occurred_at_gteq]'] = occurredAtGteq.toUtc().toIso8601String();
  if (occurredAtLteq != null) query['q[occurred_at_lteq]'] = occurredAtLteq.toUtc().toIso8601String();
  if (sortBy != null) query['q[s]'] = sortBy;

  final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries').replace(queryParameters: query);
  final response = await http.get(uri, headers: _headers);

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception('엔트리 검색 실패: ${response.statusCode}');
}
```

**사용 예시:**

```dart
// kind가 "expense"이고 amount 오름차순 정렬
final result = await client.searchEntries(
  topicId: 42,
  kindEq: 'expense',
  sortBy: 'amount asc',
);

// 날짜 범위 필터
final result = await client.searchEntries(
  topicId: 42,
  occurredAtGteq: DateTime(2026, 1, 1),
  occurredAtLteq: DateTime(2026, 1, 31, 23, 59, 59),
);
```

---

## Flutter 사용 예제

아래 예제는 Flutter에서 `http` 패키지를 사용하여 Entry API를 호출하는 방법을 보여줍니다.

### 준비

`pubspec.yaml`에 `http` 패키지를 추가합니다:

```yaml
dependencies:
  http: ^1.2.0
```

### API 클라이언트 예제

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EntryApiClient {
  final String baseUrl;
  final String token;

  EntryApiClient({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'x-token': token,
        'content-type': 'application/json',
      };

  // 엔트리 생성
  Future<Map<String, dynamic>> createEntry({
    required int topicId,
    String? kind,
    String currency = 'usd',
    int amount = 0,
    String? category,
    String? title,
    String? content,
    bool checked = false,
    DateTime? occurredAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries');
    final body = <String, dynamic>{
      if (kind != null) 'kind': kind,
      'currency': currency,
      'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      'checked': checked,
      if (occurredAt != null) 'occurred_at': occurredAt.toUtc().toIso8601String(),
    };

    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 생성 실패: ${response.statusCode} ${response.body}');
  }

  // 엔트리 목록 조회
  Future<Map<String, dynamic>> listEntries({required int topicId}) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 목록 조회 실패: ${response.statusCode}');
  }

  // 엔트리 단건 조회
  Future<Map<String, dynamic>> getEntry({
    required int topicId,
    required int entryId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries/$entryId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 조회 실패: ${response.statusCode}');
  }

  // 엔트리 수정
  Future<Map<String, dynamic>> updateEntry({
    required int topicId,
    required int entryId,
    String? kind,
    String? currency,
    int? amount,
    String? category,
    String? title,
    String? content,
    bool? checked,
    DateTime? occurredAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries/$entryId');
    final body = <String, dynamic>{
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
      if (occurredAt != null) 'occurred_at': occurredAt.toUtc().toIso8601String(),
    };

    final response = await http.patch(uri, headers: _headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 수정 실패: ${response.statusCode} ${response.body}');
  }

  // 엔트리 삭제 (soft delete)
  Future<Map<String, dynamic>> deleteEntry({
    required int topicId,
    required int entryId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries/$entryId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 삭제 실패: ${response.statusCode}');
  }
}
```

### 사용 예제

```dart
void main() async {
  final client = EntryApiClient(
    baseUrl: 'https://api.example.com',
    token: 'your_user_token_here',
  );

  const topicId = 42;

  // 엔트리 생성
  final created = await client.createEntry(
    topicId: topicId,
    kind: 'expense',
    currency: 'krw',
    amount: 15000,
    category: 'food',
    title: '점심',
    content: '팀 점심 식사',
    occurredAt: DateTime(2026, 1, 1, 12),
  );
  print('생성됨: ${created['id']}');

  // 엔트리 목록 조회
  final list = await client.listEntries(topicId: topicId);
  print('총 ${list['total']}개');
  for (final entry in list['records'] as List) {
    print('  [${entry['id']}] ${entry['title'] ?? entry['kind']} - ${entry['amount']}');
  }

  // 엔트리 수정
  final updated = await client.updateEntry(
    topicId: topicId,
    entryId: created['id'] as int,
    amount: 20000,
    checked: true,
  );
  print('수정됨: amount=${updated['amount']}, checked=${updated['checked']}');

  // 엔트리 삭제
  final deleted = await client.deleteEntry(
    topicId: topicId,
    entryId: created['id'] as int,
  );
  print('삭제됨: deleted_at=${deleted['deleted_at']}');
}
```

---

## API 엔드포인트 요약

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `POST` | `/api/v1/my/topics/{topic_id}/entries` | 엔트리 생성 |
| `GET` | `/api/v1/my/topics/{topic_id}/entries` | 엔트리 목록 조회 (ransack 검색/정렬 지원) |
| `GET` | `/api/v1/my/topics/{topic_id}/entries/{id}` | 엔트리 단건 조회 |
| `PATCH` | `/api/v1/my/topics/{topic_id}/entries/{id}` | 엔트리 수정 |
| `DELETE` | `/api/v1/my/topics/{topic_id}/entries/{id}` | 엔트리 삭제 (soft delete) |


---

## 목차

1. [인증](#인증)
2. [공통 응답 코드](#공통-응답-코드)
3. [엔트리 필드](#엔트리-필드)
4. [엔트리 API](#엔트리-api)
   - [엔트리 생성](#1-엔트리-생성)
   - [엔트리 목록 조회](#2-엔트리-목록-조회)
   - [엔트리 단건 조회](#3-엔트리-단건-조회)
   - [엔트리 수정](#4-엔트리-수정)
   - [엔트리 삭제](#5-엔트리-삭제)
5. [Flutter 사용 예제](#flutter-사용-예제)

---

## 인증

모든 API 요청에는 `x-token` 헤더가 필요합니다.

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 인증 토큰 (User.token 값) |
| `content-type` | ✅ (바디 있는 경우) | `application/json` |

헤더가 없으면 **401 Unauthorized** 응답이 반환됩니다.

---

## 공통 응답 코드

| 상태 코드 | 설명 |
|-----------|------|
| `200` | 요청 성공 |
| `201` | 리소스 생성 성공 |
| `400` | 잘못된 요청 (필수 파라미터 누락 등) |
| `401` | 인증 실패 (`x-token` 헤더 없음 또는 유효하지 않음) |
| `404` | 리소스를 찾을 수 없음 (토픽 또는 엔트리 없음) |
| `500` | 서버 내부 오류 |

---

## 엔트리 필드

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `id` | integer | — | — | 엔트리 고유 ID |
| `topic_id` | integer | — | — | 소속 토픽 ID |
| `created_by_id` | integer | — | — | 생성한 사용자 ID |
| `updated_by_id` | integer | — | — | 마지막으로 수정한 사용자 ID |
| `occurred_at` | datetime (ISO 8601) | ❌ | `null` | 항목 발생 시각 |
| `kind` | string | ❌ | `null` | 항목 종류 (예: `"expense"`, `"income"`) |
| `currency` | string | ❌ | `"usd"` | 통화 코드 (예: `"krw"`, `"usd"`) |
| `amount` | integer | ❌ | `0` | 금액 |
| `category` | string | ❌ | `null` | 카테고리 (예: `"food"`, `"transport"`) |
| `title` | string | ❌ | `null` | 항목 제목 |
| `content` | string | ❌ | `null` | 항목 내용 |
| `checked` | boolean | ❌ | `false` | 확인 여부 |
| `deleted_at` | datetime | — | `null` | soft delete 시각 (null이면 활성 상태) |
| `created_at` | datetime | — | — | 생성 시각 |
| `updated_at` | datetime | — | — | 마지막 수정 시각 |

---

## 엔트리 API

모든 엔드포인트는 `/api/v1/my/topics/:topic_id/entries` 하위에 있습니다.
`topic_id`는 엔트리를 관리할 토픽의 숫자 ID입니다.

---

### 1. 엔트리 생성

새로운 엔트리를 생성합니다. `created_by`와 `updated_by`는 인증된 사용자로 자동 설정됩니다.

- **메서드**: `POST`
- **경로**: `/api/v1/my/topics/{topic_id}/entries`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 엔트리를 추가할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |
| `content-type` | ✅ | `application/json` |

**바디** (모든 필드 선택)

```json
{
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false
}
```

#### 응답

**201 Created**

```json
{
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 7,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-01T12:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl -X POST https://api.example.com/api/v1/my/topics/42/entries \
  -H "x-token: YOUR_TOKEN" \
  -H "content-type: application/json" \
  -d '{"kind": "expense", "currency": "krw", "amount": 15000, "category": "food", "title": "점심"}'
```

---

### 2. 엔트리 목록 조회

토픽에 속한 모든 엔트리를 최신순으로 반환합니다. soft delete된 항목은 제외됩니다.

- **메서드**: `GET`
- **경로**: `/api/v1/my/topics/{topic_id}/entries`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 조회할 토픽 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |

#### 응답

**200 OK**

```json
{
  "total": 2,
  "records": [
    {
      "id": 2,
      "topic_id": 42,
      "created_by_id": 7,
      "updated_by_id": 7,
      "occurred_at": "2026-01-02T09:00:00.000Z",
      "kind": "income",
      "currency": "krw",
      "amount": 50000,
      "category": "salary",
      "title": null,
      "content": null,
      "checked": false,
      "deleted_at": null,
      "created_at": "2026-01-02T09:00:00.000Z",
      "updated_at": "2026-01-02T09:00:00.000Z"
    },
    {
      "id": 1,
      "topic_id": 42,
      "created_by_id": 7,
      "updated_by_id": 7,
      "occurred_at": "2026-01-01T12:00:00.000Z",
      "kind": "expense",
      "currency": "krw",
      "amount": 15000,
      "category": "food",
      "title": "점심",
      "content": "팀 점심 식사",
      "checked": false,
      "deleted_at": null,
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z"
    }
  ]
}
```

#### 예시 (curl)

```bash
curl https://api.example.com/api/v1/my/topics/42/entries \
  -H "x-token: YOUR_TOKEN"
```

---

### 3. 엔트리 단건 조회

특정 엔트리를 조회합니다.

- **메서드**: `GET`
- **경로**: `/api/v1/my/topics/{topic_id}/entries/{id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `id` | ✅ | 엔트리 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |

#### 응답

**200 OK**

```json
{
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 7,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-01T12:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl https://api.example.com/api/v1/my/topics/42/entries/1 \
  -H "x-token: YOUR_TOKEN"
```

---

### 4. 엔트리 수정

엔트리를 수정합니다. 수정 시 `updated_by`는 현재 인증된 사용자로 자동 갱신됩니다.
수정할 필드만 포함하면 됩니다.

- **메서드**: `PATCH`
- **경로**: `/api/v1/my/topics/{topic_id}/entries/{id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `id` | ✅ | 수정할 엔트리 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |
| `content-type` | ✅ | `application/json` |

**바디** (수정할 필드만 포함)

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
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 8,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 20000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": true,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-02T09:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl -X PATCH https://api.example.com/api/v1/my/topics/42/entries/1 \
  -H "x-token: YOUR_TOKEN" \
  -H "content-type: application/json" \
  -d '{"amount": 20000, "checked": true}'
```

---

### 5. 엔트리 삭제

엔트리를 soft delete 처리합니다 (`deleted_at` 필드가 설정됩니다). 삭제된 엔트리는 목록 조회 시 제외됩니다.

- **메서드**: `DELETE`
- **경로**: `/api/v1/my/topics/{topic_id}/entries/{id}`

#### 요청

**경로 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `topic_id` | ✅ | 토픽 ID |
| `id` | ✅ | 삭제할 엔트리 ID |

**헤더**

| 헤더 | 필수 | 설명 |
|------|------|------|
| `x-token` | ✅ | 사용자 토큰 |

#### 응답

**200 OK** — 삭제된 엔트리 반환

```json
{
  "id": 1,
  "topic_id": 42,
  "created_by_id": 7,
  "updated_by_id": 7,
  "occurred_at": "2026-01-01T12:00:00.000Z",
  "kind": "expense",
  "currency": "krw",
  "amount": 15000,
  "category": "food",
  "title": "점심",
  "content": "팀 점심 식사",
  "checked": false,
  "deleted_at": "2026-01-02T09:00:00.000Z",
  "created_at": "2026-01-01T12:00:00.000Z",
  "updated_at": "2026-01-02T09:00:00.000Z"
}
```

#### 예시 (curl)

```bash
curl -X DELETE https://api.example.com/api/v1/my/topics/42/entries/1 \
  -H "x-token: YOUR_TOKEN"
```

---

## Flutter 사용 예제

아래 예제는 Flutter에서 `http` 패키지를 사용하여 Entry API를 호출하는 방법을 보여줍니다.

### 준비

`pubspec.yaml`에 `http` 패키지를 추가합니다:

```yaml
dependencies:
  http: ^1.2.0
```

### API 클라이언트 예제

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EntryApiClient {
  final String baseUrl;
  final String token;

  EntryApiClient({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'x-token': token,
        'content-type': 'application/json',
      };

  // 엔트리 생성
  Future<Map<String, dynamic>> createEntry({
    required int topicId,
    String? kind,
    String currency = 'usd',
    int amount = 0,
    String? category,
    String? title,
    String? content,
    bool checked = false,
    DateTime? occurredAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries');
    final body = <String, dynamic>{
      if (kind != null) 'kind': kind,
      'currency': currency,
      'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      'checked': checked,
      if (occurredAt != null) 'occurred_at': occurredAt.toUtc().toIso8601String(),
    };

    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 생성 실패: ${response.statusCode} ${response.body}');
  }

  // 엔트리 목록 조회
  Future<Map<String, dynamic>> listEntries({required int topicId}) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 목록 조회 실패: ${response.statusCode}');
  }

  // 엔트리 단건 조회
  Future<Map<String, dynamic>> getEntry({
    required int topicId,
    required int entryId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries/$entryId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 조회 실패: ${response.statusCode}');
  }

  // 엔트리 수정
  Future<Map<String, dynamic>> updateEntry({
    required int topicId,
    required int entryId,
    String? kind,
    String? currency,
    int? amount,
    String? category,
    String? title,
    String? content,
    bool? checked,
    DateTime? occurredAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries/$entryId');
    final body = <String, dynamic>{
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
      if (occurredAt != null) 'occurred_at': occurredAt.toUtc().toIso8601String(),
    };

    final response = await http.patch(uri, headers: _headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 수정 실패: ${response.statusCode} ${response.body}');
  }

  // 엔트리 삭제 (soft delete)
  Future<Map<String, dynamic>> deleteEntry({
    required int topicId,
    required int entryId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/my/topics/$topicId/entries/$entryId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('엔트리 삭제 실패: ${response.statusCode}');
  }
}
```

### 사용 예제

```dart
void main() async {
  final client = EntryApiClient(
    baseUrl: 'https://api.example.com',
    token: 'your_user_token_here',
  );

  const topicId = 42;

  // 엔트리 생성
  final created = await client.createEntry(
    topicId: topicId,
    kind: 'expense',
    currency: 'krw',
    amount: 15000,
    category: 'food',
    title: '점심',
    content: '팀 점심 식사',
    occurredAt: DateTime(2026, 1, 1, 12),
  );
  print('생성됨: ${created['id']}');

  // 엔트리 목록 조회
  final list = await client.listEntries(topicId: topicId);
  print('총 ${list['total']}개');
  for (final entry in list['records'] as List) {
    print('  [${entry['id']}] ${entry['title'] ?? entry['kind']} - ${entry['amount']}');
  }

  // 엔트리 수정
  final updated = await client.updateEntry(
    topicId: topicId,
    entryId: created['id'] as int,
    amount: 20000,
    checked: true,
  );
  print('수정됨: amount=${updated['amount']}, checked=${updated['checked']}');

  // 엔트리 삭제
  final deleted = await client.deleteEntry(
    topicId: topicId,
    entryId: created['id'] as int,
  );
  print('삭제됨: deleted_at=${deleted['deleted_at']}');
}
```

---

## API 엔드포인트 요약

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `POST` | `/api/v1/my/topics/{topic_id}/entries` | 엔트리 생성 |
| `GET` | `/api/v1/my/topics/{topic_id}/entries` | 엔트리 목록 조회 |
| `GET` | `/api/v1/my/topics/{topic_id}/entries/{id}` | 엔트리 단건 조회 |
| `PATCH` | `/api/v1/my/topics/{topic_id}/entries/{id}` | 엔트리 수정 |
| `DELETE` | `/api/v1/my/topics/{topic_id}/entries/{id}` | 엔트리 삭제 (soft delete) |
