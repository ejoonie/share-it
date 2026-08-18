import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';
import 'expense_provider.dart';

/// 내가 소유/구독하는 토픽 목록이 바뀔 수 있는 모든 이벤트(구독, 구독 해제, 그리고
/// 앞으로 추가될 토픽 생성/초대 수락 등)는 이 한 곳만 호출하면 된다.
///
/// - Filter/Add Expense/Amount Entry가 쓰는 [myViewableTopicsProvider] 캐시를 무효화한다.
/// - [justSubscribedTopicId]가 주어지면(=방금 구독한 토픽이 있으면) 그 토픽을 달력
///   Filter의 현재 선택에도 자동으로 포함시킨다.
///
/// 호출 지점이 이 두 가지를 각각 따로 챙길 필요가 없도록 하나로 묶어 둔 것으로,
/// 새 진입점이 생겨도 여기 한 줄만 호출하면 된다.
Future<void> notifyTopicListChanged(
  Ref ref, {
  int? justSubscribedTopicId,
}) async {
  ref.invalidate(myViewableTopicsProvider);
  if (justSubscribedTopicId != null) {
    await ref
        .read(expenseNotifierProvider.notifier)
        .includeTopicInSelection(justSubscribedTopicId);
  }
}
