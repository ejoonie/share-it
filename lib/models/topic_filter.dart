/// 달력 Filter가 조회할 토픽 범위를 나타낸다.
///
/// 세 가지 상태를 명시적으로 구분한다 (이전에는 `Set<int>?`로 표현해
/// null=전체/빈 Set=전체 해제/그 외=부분 선택을 암묵적으로 구분했다):
/// - [TopicFilterAll]: 기본값. 필터를 적용한 적이 없어 모든 토픽을 보여준다.
/// - [TopicFilterNone]: 사용자가 전체 선택을 해제했다. 조회 결과는 0건이다.
/// - [TopicFilterSelected]: 사용자가 고른 토픽만 조회한다.
sealed class TopicFilter {
  const TopicFilter();
}

class TopicFilterAll extends TopicFilter {
  const TopicFilterAll();

  @override
  bool operator ==(Object other) => other is TopicFilterAll;

  @override
  int get hashCode => runtimeType.hashCode;
}

class TopicFilterNone extends TopicFilter {
  const TopicFilterNone();

  @override
  bool operator ==(Object other) => other is TopicFilterNone;

  @override
  int get hashCode => runtimeType.hashCode;
}

class TopicFilterSelected extends TopicFilter {
  final Set<int> topicIds;

  const TopicFilterSelected(this.topicIds);

  @override
  bool operator ==(Object other) =>
      other is TopicFilterSelected &&
      other.topicIds.length == topicIds.length &&
      other.topicIds.containsAll(topicIds);

  @override
  int get hashCode => Object.hashAllUnordered(topicIds);
}

extension TopicFilterX on TopicFilter {
  /// [topicId]가 이 필터에 포함되는지. Filter 체크박스 렌더링에 쓴다.
  bool isSelected(int topicId) => switch (this) {
        TopicFilterAll() => true,
        TopicFilterNone() => false,
        TopicFilterSelected(:final topicIds) => topicIds.contains(topicId),
      };

  /// API 조회에 쓸 topic_id 목록. all이면 필터 없음(null), none이면 빈 목록
  /// (서버 호출 없이 바로 빈 결과), selected면 해당 목록.
  List<int>? get queryTopicIds => switch (this) {
        TopicFilterAll() => null,
        TopicFilterNone() => const [],
        TopicFilterSelected(:final topicIds) => topicIds.toList(),
      };

  /// [topicId]를 포함하도록 확장한다. 이미 전체(all)거나 이미 포함돼 있으면 그대로 둔다.
  /// 새로 구독한 토픽을 현재 필터에 자동으로 포함시킬 때 쓴다.
  TopicFilter includingTopic(int topicId) => switch (this) {
        TopicFilterAll() => this,
        TopicFilterNone() => TopicFilterSelected({topicId}),
        TopicFilterSelected(:final topicIds) => topicIds.contains(topicId)
            ? this
            : TopicFilterSelected({...topicIds, topicId}),
      };
}
