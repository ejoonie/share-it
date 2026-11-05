# Sharable Piggy 디자인 시스템 v1

현재 달력·거래 내역에서 확정한 **흰 배경 + 라벤더 카드 + 블루퍼플 + 블루·코랄**을 기준으로 한다. 화면은 깨끗한 흰색으로 열어 두고, 명랑함은 선명한 금액과 의미 있는 카드색에서 만든다.

## 실행과 코드 위치

- 앱의 개발 빌드: **Settings → 오른쪽 위 팔레트 버튼 → Design system**.
- 서버·Firebase·로그인 없이 카탈로그만 실행: `flutter run -t lib/design_system_preview.dart`.
- 새 화면은 `lib/design_system/design_system.dart` 하나를 import한다.
- 디자인 값의 원본: `lib/design_system/tokens.dart`.
- Flutter 기본 컨트롤과 상태: `lib/design_system/theme.dart`.
- 재사용 컴포넌트의 공개 진입점: `lib/design_system/components.dart`.
- 컴포넌트 구현: `lib/design_system/components/`의 역할별 파일. 화면에서는 개별 파일 대신 공개 진입점을 사용한다.
- 실제 위젯을 보여주는 카탈로그: `lib/screens/design_system_screen.dart`.
- 기존 `AppTheme`, `LedgerStyle`은 호환용 이름이다. 값을 별도로 복제하지 않는다.

카탈로그의 거래와 금액은 샘플이며 저장되지 않는다. 버튼은 미리보기 알림만 표시한다. 개발 빌드의 진입점은 릴리스에서 노출하지 않는다.

## 1. 색상

| 토큰 | 색 | 용도 |
| --- | --- | --- |
| `background` | `#FFFFFF` | 화면의 깨끗한 기본 배경 |
| `surface` | `#FFFFFF` | 입력, 모달, 하단 탐색 |
| `card` | `#F8F7FC` | 일반 거래 묶음과 중립 카드 |
| `ink` | `#252334` | 제목·본문, 보라 기가 도는 짙은 글자 |
| `secondary` | `#747080` | 요일·장부·설명 |
| `muted` | `#A39EAD` | 다른 달 날짜, 비활성 보조 정보 |
| `line` | `#ECEAF2` | 장식용 구분선·카드 경계 |
| `accent` | `#5B57E8` | 주요 행동·선택 날짜·활성 탭 |
| `accentSoft` | `#F0EFFF` | 선택 탭과 브랜드 보조 면 |
| `income` / `incomeSoft` | `#3966CE` / `#EEF4FF` | 수입 금액·아이콘 / 배경 |
| `expense` / `expenseSoft` | `#B9473E` / `#FFF0EA` | 지출 금액·아이콘 / 배경 |
| `error` / `errorSoft` | `#B52D45` / `#FFEDEF` | 입력 오류·실패·삭제 |
| `success` / `successSoft` | `#287452` / `#EAF5EF` | 저장 완료 등 성공 피드백 |
| `warning` / `warningSoft` | `#8F5B10` / `#FFF3D9` | 확인이 필요한 상태 |

카드는 중립·수입·지출의 세 면만 사용한다. 일반 거래는 옅은 라벤더, 수입은 소프트 블루, 지출은 소프트 피치다. 코랄 전경은 밝은 피치 배경에서도 작은 글자가 읽히는 `#B9473E`를 유지한다.

`PiggyTone.brand`, `.income`, `.expense`, `.neutral`로 전경과 배경을 함께 선택한다. 수입·지출에는 색과 `+ / −`, 라벨을 함께 사용한다. **지출은 오류가 아니므로** 오류 메시지에는 별도 `error` 역할을 쓴다. 성공을 알리는 작은 녹색은 허용하지만 브랜드나 화면 전체의 포인트로 확장하지 않는다.

본문과 의미 있는 금액은 지정된 짙은 전경색을 쓴다. `muted`, `line`은 본문·필수 설명·포커스 표시에 사용하지 않는다. 흰색 글자는 `accent` 같은 충분히 진한 면에서만 쓴다.

## 2. 글자

기본 iOS/Android 시스템 글꼴을 사용한다. 웹 폰트나 외부 폰트 다운로드는 없다. 사용자의 글자 확대를 끄지 않는다.

| 토큰 | 크기 / 굵기 | 용도 |
| --- | --- | --- |
| `pageTitle` | 20 / 700 | 월·화면 제목 |
| `sectionTitle` | 17 / 700 | 선택 날짜·섹션 제목 |
| `summaryAmount` | 24 / 700 | 월 수입·지출 |
| `amount` | 14 / 700 | 거래 금액 |
| `itemTitle` | 14 / 600 | 거래 제목 |
| `body` | 14 / 400 | 본문 |
| `label` | 12 / 600 | 짧은 라벨 |
| `caption` | 12 / 400 | 보조 설명 |
| `metadata` | 11 / 400 | 장부·카테고리·탭 |
| `calendarDay` | 13 | 날짜 숫자 |
| `calendarAmount` | 9 | 달력 안의 축약 금액에만 사용 |

금액에는 고정폭 숫자 기능을 적용한다. 정확한 통화·부호·소수점 처리는 화면의 책임이다. 디자인 컴포넌트는 이미 포맷된 문자열을 받는다.

달력의 9 pt 금액은 공간이 제한된 개요 표시다. 정확한 금액은 날짜를 선택한 뒤 내역에서 읽게 하고, 스크린리더에는 전체 금액을 제공한다. 긴 제목과 장부는 한 줄 말줄임, 상세 화면에서 전체 확인. 큰 금액은 요약 카드에서 축소하여 표시한다.

## 3. 간격과 모서리

- `PiggySpace`: 4 / 8 / 12 / 16 / **20** / 24 / 32.
- 화면 좌우 기본 여백: 16. 카드 안쪽: 12~16. 관련 카드 사이: 8~12.
- `PiggyRadius`: 아이콘·입력·버튼 12, 일반 카드 16, 요약 카드 18, 시트·대화상자 24.
- 기본 버튼 높이 48, 터치 영역 최소 44. 숫자 원 30은 시각적 크기이며 달력 전체 셀이 터치 영역이다.
- 거래 아이콘 면 38, 아이콘 19. 달력 행 52. 하단 탭 높이 64 + 시스템 안전 영역.
- 넓은 미리보기의 최대 내용 폭은 640. 모바일 화면은 세로 스크롤과 안전 영역을 유지한다.
- 그림자를 겹쳐서 깊이를 만들지 않는다. 기본 표면은 평평하며 색·여백·얇은 구분선으로 나눈다.

기존 화면의 1·2·3·5 pt 같은 값은 테두리·타이포그래피의 광학적 보정이다. 새 레이아웃의 간격은 우선 공용 스케일을 사용한다.

## 4. 컴포넌트와 사용법

| 컴포넌트 | 책임 |
| --- | --- |
| `PiggySurface` | 배경·모서리·안쪽 여백 |
| `PiggySummaryCard` | 라벨·방향 아이콘·큰 금액 |
| `PiggyDailySummaryCard` | 선택 날짜와 해당 날짜의 수입·지출 통합 요약 |
| `PiggyCategoryIcon` | 의미에 맞는 아이콘과 연한 배경 |
| `PiggyAddButton` | 툴팁과 44 pt 터치 영역을 가진 추가 행동 |
| `PiggyFloatingAddButton` | 목록 위에 놓이는 플로팅 추가 행동 |
| `PiggySlideVisibility` | 레이아웃 크기를 바꾸지 않고 플로팅 UI를 숨기고 표시하는 전환 |
| `PiggyDayMarker` | 기본·오늘·선택·다른 달의 시각적 상태 |
| `PiggyTransactionRow` | 제목·보조 설명·부호 있는 금액·선택적 메뉴 |
| `PiggyNavigationBar` | 반투명 블러 면·선택 탭·탭 전환 콜백 |

표준 `FilledButton`, `OutlinedButton`, `TextButton`, `TextField`, `Card`, `Dialog`, `BottomSheet`는 `PiggyTheme.light`를 따른다. 같은 용도의 별도 버튼 위젯을 화면마다 만들지 않는다.

```dart
import 'package:share_it/design_system/design_system.dart';

PiggySummaryCard(
  label: 'Expenses',
  amount: formatter.format(total),
  tone: PiggyTone.expense,
  icon: Icons.north_east_rounded,
);

PiggyTransactionRow(
  title: transaction.title,
  subtitle: 'Food · My First Piggy',
  amount: '−\$12.00',
  icon: Icons.restaurant_rounded,
  tone: PiggyTone.expense,
  first: index == 0,
  last: index == transactions.length - 1,
  onTap: openDetails,
  trailing: transactionMenu,
);
```

화면에서는 Riverpod·저장·삭제 확인·날짜 선택·통화 포맷을 관리하고, 디자인 시스템은 표시와 콜백만 담당한다. 디자인 시스템 코드에서 API나 저장소에 접근하지 않는다.

`components.dart`는 외부 import 경로를 고정하는 배럴 파일이다. 구현 파일은 `actions`, `calendar`, `motion`, `navigation`, `summary`, `surface`, `transaction`으로 나눈다. 화면에만 필요한 조합은 디자인 시스템에 넣지 않는다. 예를 들어 `ExpenseOverview`, `ExpenseFilterSheet`는 지출 기능의 상태와 문구를 아는 기능 위젯이므로 `lib/widgets/expense/`에 둔다.

## 5. 상태 규칙

- **오늘:** 코랄 얇은 테두리. **선택:** 블루퍼플로 채운 원과 흰 숫자. 오늘을 선택하면 선택 채움이 우선하며 내역 제목에 `Today`를 표시한다.
- 날짜 아래 금액은 원 밖의 한 줄에 유지한다. 부호 없이 수입은 블루, 지출은 코랄과 고정 순서로 구분한다. 선택 시 금액을 흰색으로 바꾸지 않는다.
- 기본 날짜·주말은 같은 중립 글자색. 주말 전체를 지출색으로 칠하지 않는다.
- 주요 행동은 채운 블루퍼플 버튼, 보조 행동은 외곽선 또는 텍스트 버튼.
- 비활성은 `onPressed: null`. 색만 흐리게 하고 클릭을 남기지 않는다.
- 포커스·눌림·호버는 Flutter Material 상태 동작을 유지한다. 키보드 포커스 표현을 제거하지 않는다.
- 입력 포커스는 2 pt 포인트 테두리. 오류는 오류색 테두리 + 구체적인 설명. 색만으로 오류를 전달하지 않는다.
- 거래 묶음의 첫·끝 행만 모서리를 둥글게 하고, 가운데는 얇은 구분선을 사용한다.
- 추가 버튼은 우측 하단 플로팅 버튼으로 두되 거래 금액·메뉴를 가리지 않도록 목록에 충분한 하단 여백을 둔다.
- 목록을 28 pt 이상 내려볼 때 플로팅 버튼과 하단 메뉴를 함께 숨긴다. 반대 방향으로 16 pt 이동하면 즉시 다시 표시하며 화면 최상단에서는 항상 보인다.
- 하단 메뉴는 스크롤 영역의 높이를 바꾸지 않고 화면 밖으로 슬라이드한다. Pull-to-refresh 중에는 메뉴를 표시하고 완료 후 인디케이터만 위로 접는다.
- 하단 메뉴는 화면 가장자리에서 12 pt 띄운 반투명 패널이다. 배경 콘텐츠가 약하게 비치도록 블러를 적용하고, 밝은 외곽선과 낮은 그림자로 경계를 만든다.
- 한 영역에 강한 주요 행동은 하나만 둔다. 개발 도구는 제품의 하단 탭에 겹쳐 띄우지 않는다.

## 6. 적용 범위와 변경 원칙

v1에는 토큰, 밝은 테마, 표준 컨트롤 스타일, 달력·내역 공용 컴포넌트와 라이브 카탈로그가 포함된다. 앱의 기존 `AppTheme.lightTheme`도 새 테마를 사용한다. 달력·내역은 공용 컴포넌트로 연결했다.

금액 입력·공유·설정 화면의 개별 레이아웃을 모두 재설계한 것은 아니다. 이 화면에 남아 있는 직접 지정 색·간격은 화면을 수정할 때 공용 토큰으로 교체한다. 다크 모드, Figma 라이브러리, 웹 디자인 시스템은 v1 범위에 포함하지 않는다.

새 스타일은 먼저 기존 역할로 표현할 수 있는지 확인한다. 새로운 역할이 필요하면 토큰 → 테마/컴포넌트 → 카탈로그 → 이 문서 순으로 함께 갱신한다. 기본 팔레트를 화면별로 복제하지 않는다. 기존 `AppTheme`·`LedgerStyle`에는 새 독립 값을 추가하지 않는다.

```sh
flutter analyze lib/design_system lib/screens/design_system_screen.dart
flutter test test/widgets/design_system_test.dart test/widgets/expense_ledger_test.dart
flutter run -t lib/design_system_preview.dart
```

색상 대비 검사는 본문·금액·행동 색의 지정 조합을 검사한다. 화면 검증에서는 작은 화면과 글자 확대, 오늘+선택 중첩, 필터 빈 상태와 긴 금액을 확인한다. 자동 검사를 전체 접근성 인증으로 간주하지 않는다.

## Dialogs and modal sheets

Use `showPiggyConfirmation` for all confirmation prompts. It returns `true` only
for the primary action, `false` for Cancel, and `null` for route dismissal.
Use `destructive: true` for deletion; ordinary actions such as signing out and
notification opt-in use the brand color. The shared component owns the icon tile,
heading, message, optional detail card, and responsive actions. It scrolls on short
screens and stacks buttons for narrow screens or enlarged text.

Use `showPiggySheet<T>` for bottom sheets and `showPiggyDatePicker` for dates.
The shell owns the scrim, safe area, drag handle, width cap, and rounded surface;
form content owns keyboard insets and scrolling. Avoid custom handles and local
modal shapes. `PiggyTheme.light.datePickerTheme` owns the calendar appearance.
Preview confirmation, deletion, and date selection in Settings → Design system.
