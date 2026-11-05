# 지출별 채팅 API

각 Entry를 하나의 대화로 사용한다. 별도 채팅방/참여자 테이블 없이 현재 TopicFollow로 접근을 판단한다. 수입·쇼핑 등 다른 Entry 종류에도 동일하게 사용할 수 있다.

## DB 구조

`entry_messages`

| 필드 | 타입 | 제약/설명 |
| --- | --- | --- |
| id | bigint | PK, 페이지 커서 |
| entry_id | bigint | NOT NULL, entries FK |
| user_id | bigint | NOT NULL, users FK, 작성자 |
| body | text | NOT NULL, 앞뒤 공백 제거 후 1–2,000자 |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL, 수정 시 갱신 |

`(entry_id, id)` 복합 인덱스로 대화별 최신순 조회와 이전 메시지 탐색을 지원한다. user_id에도 인덱스가 있다. DB에서도 본문 길이를 검사한다. Entry/User 영구 삭제 시 FK의 ON DELETE CASCADE로 메시지를 삭제한다. Entry/Topic 소프트 삭제 시 메시지는 보관하되 API 접근은 차단한다.

## 인증·권한

기존 API와 동일하게 `x-token` 헤더를 사용한다. 인증 없는 요청·잘못된 토큰·레거시 게스트는 401이다.

- 활성 Topic의 현재 구독자는 대화를 조회하고 작성할 수 있다. 지출 create/edit/delete 권한과 채팅 참여 권한은 별개다.
- `banned` 권한이 있으면 다른 권한과 함께 있어도 모든 채팅 요청을 403으로 거절한다.
- 미구독·구독 해제·삭제된 Topic/Entry는 404다.
- 메시지 수정·삭제는 작성자만 가능하다. Topic 소유자도 다른 사람의 메시지를 수정·삭제할 수 없다(403).
- 다른 Entry의 메시지 ID를 요청하면 404다.
- 사용자 ID는 요청에서 받지 않고 인증된 사용자로 지정한다. 작성자 응답은 ID와 닉네임만 포함한다.

## 엔드포인트

기본 경로: `/api/v1/entries/{entry_id}/messages`

| 메서드 | 경로 | 결과 |
| --- | --- | --- |
| GET | 기본 경로 | 200, 최신순 목록 |
| POST | 기본 경로 | 201, 생성한 메시지 |
| GET | 기본 경로 + `/{message_id}` | 200, 메시지 단건 (삭제됨: `404 code=message_not_found`) |
| PATCH | 기본 경로 + `/{message_id}` | 200, 수정한 메시지 |
| DELETE | 기본 경로 + `/{message_id}` | 204, 본문 없이 영구 삭제 |

POST/PATCH JSON:

```json
{"body":"여기 어디야?"}
```

메시지 응답 예시:

```json
{
  "id": 101,
  "entry_id": 42,
  "body": "여기 어디야?",
  "author": {"id": 7, "nick_name": "민지"},
  "created_at": "2026-11-05T15:00:00.000Z",
  "updated_at": "2026-11-05T15:00:00.000Z"
}
```

본문 누락·null·빈 문자열 등 파라미터 오류는 400이다. 공백 제거 후 빈 본문이나 2,000자 초과 등 모델 검증 실패는 422와 `message`, `errors`를 반환한다. 클라이언트는 본문을 일반 텍스트로 렌더링한다.

### 목록과 페이지네이션

`GET .../messages?limit=30&before_id=101`

- limit: 기본 30, 1–100.
- before_id: 선택, 양의 bigint. 해당 ID보다 작은 메시지를 조회한다.
- records는 ID 내림차순이다. 채팅 화면에서 시간 오름차순으로 보여주려면 클라이언트가 순서를 뒤집는다.
- 첫 조회는 before_id를 생략한다. 이전 대화는 next_before_id로 이어서 요청한다.

```json
{
  "records": [],
  "has_more": false,
  "next_before_id": null
}
```

더 가져올 메시지가 있으면 has_more=true, next_before_id=이번 페이지의 마지막 메시지 ID다. 페이지 사이에 새 메시지가 생겨도 이전 페이지와 중복되지 않는다.

## 실시간 연결

1. 인증된 앱이 `POST /api/v1/entries/{entry_id}/messages/connection_ticket`를 호출한다. 응답은 `201 {"ticket":"..."}`이며 기존 지출 접근 권한을 확인한다.
2. 같은 API 호스트의 `/cable?ticket=...`에 연결한다(HTTPS이면 WSS). 티켓은 사용자·지출에 한정되고 1분 뒤 만료된다. 만료는 새 연결 수립에 적용된다.
3. Action Cable의 welcome 이후 `{"command":"subscribe","identifier":"{\"channel\":\"EntryMessagesChannel\",\"entry_id\":42}"}`를 전송한다.
4. `confirm_subscription` 이후 대화를 REST로 재조회한다. 서버가 `message: {"type":"changed","message_id":101}`를 보내면 해당 메시지만 단건 조회한다. 삭제된 메시지는 `404 code=message_not_found`로 확인하고 해당 말풍선만 제거한다. 지출 접근 불가 404와 구분한다.

메시지 생성·수정·삭제 트랜잭션 커밋 후 변경 신호를 전송한다. 본문은 전송하지 않으며 REST에서 최신 권한을 재검사한다. 채널도 신호를 전달할 때마다 사용자·구독·차단·Entry/Topic 삭제 여부를 확인한다. 권한이 사라지면 `access_revoked`를 보내고 스트림을 중단한다. 권한 변경 자체를 즉시 전파하는 기능은 없으며, 다음 변경 신호나 REST 요청 시 차단된다.

Flutter 앱은 연결 끊김 시 1/2/4/8/16초 간격으로 새 티켓을 발급받아 재연결한다. 서버 heartbeat가 20초간 없을 때도 연결을 재시도한다. 앱 복귀 시 연결을 재생성한다. 연결 확인 시 이미 불러온 대화 범위를 재조회해 누락·수정·삭제를 복구하며, REST 쓰기와 동시에 발생한 이벤트는 쓰기 완료 후 합쳐 처리한다. 조회 중 도착한 이벤트도 후속 조회로 처리한다.

단건 변경 수신 시 이미 불러온 범위 안의 메시지와 새 메시지만 목록에 반영한다. 범위 밖의 오래된 수정은 다음 페이지 조회에서 가져오며, 이전 페이지 병합은 ID로 중복 제거하고 최신 수정 시각을 우선한다. 단건 조회의 네트워크 오류·408·429·5xx는 1/2/4/8/16초(상한) 간격으로 재시도한다. 화면 종료·접근 권한 상실 시 재시도를 취소한다. 이전 페이지 조회 중 로컬 쓰기가 겹치면 요청 커서를 보관해 쓰기 완료 후 자동 재조회한다.

화면은 연결 상태를 `Conversation · Live`로 표시한다. 이전 대화는 페이지로 추가 조회한다. 입력 중인 초안은 실시간 갱신 시에도 유지하며, 메시지 편집을 시작할 때 별도로 보관해 편집 취소·저장·편집 대상 삭제 시 복원한다. 백그라운드 조회 중에도 전송과 메시지 메뉴를 사용할 수 있다. POST 중복 방지 키, 푸시 알림, 입력 중 표시, 읽음 상태, 반응·첨부파일은 포함하지 않는다.

### 운영 설정

- `/cable` WebSocket 업그레이드를 허용해야 한다. 저장소의 Nginx 설정에 업그레이드 헤더와 타임아웃을 추가했다.
- production은 `async` 어댑터를 사용하며 Redis가 필요 없다. Puma는 `workers 0`으로 단일 프로세스 모드를 명시한다. Rails 컨테이너도 하나만 실행해야 한다. 여러 스레드는 사용할 수 있지만 별도 프로세스/콘솔/작업 서버에서 발생한 방송은 전달되지 않는다. 서버를 여러 프로세스나 인스턴스로 확장하기 전에 공통 메시지 어댑터로 변경해야 한다.
- 네이티브 앱은 Origin 없이 서명 티켓으로 인증한다. 브라우저는 Rails의 기본 origin 검사를 유지한다. 별도 웹 호스트는 `CABLE_ALLOWED_ORIGINS=https://app.example.com`처럼 정확한 origin을 지정한다(쉼표로 복수 지정).
- 운영 앱은 HTTPS/WSS를 사용한다. 티켓은 로그 필터에 등록했고 Nginx `/cable` 접근 로그는 비활성화했다. 앞단 로드밸런서/CDN도 티켓 쿼리를 기록하지 않도록 설정한다.
- 방송 실패나 서버 재시작이 있어도 PostgreSQL에 저장된 메시지는 유지된다. 방송 실패로 이미 저장된 메시지 요청을 실패 처리하지 않는다. 방송은 영속 큐가 아니므로 이 경우 재연결/수동 새로고침 시 복구한다.
- 서버·앱 코드와 의존성·프록시 설정을 함께 배포해야 한다. 이 PR은 `CreateEntryMessages` 마이그레이션을 추가한다. 배포 시 기존 `db:prepare` 시작 절차로 적용하며, 수동 실행 환경에서는 `db:migrate`를 먼저 실행해야 한다.

참고: [Rails Action Cable](https://guides.rubyonrails.org/action_cable_overview.html), [Flutter WebSocket 라이브러리](https://pub.dev/packages/web_socket_channel).

## 적용·검증

```sh
# 배포할 환경에서 마이그레이션 적용
bundle exec rails db:migrate

# 로컬 테스트 DB
RAILS_ENV=test bundle exec rails db:migrate
bundle exec rspec spec/requests/entry_messages_api_spec.rb
```

DB 풀은 최소 `RAILS_MAX_THREADS + CABLE_WORKER_POOL_SIZE + 2`개(기본 9개)를 확보한다. `DB_POOL`은 이 값보다 크게 지정할 수 있다. 채널 권한 검사는 join 기반 EXISTS 쿼리 한 번으로 수행한다. Entry/User 일괄 삭제는 FK cascade가 처리하며 메시지별 콜백·방송을 실행하지 않는다.
