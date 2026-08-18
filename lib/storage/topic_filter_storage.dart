import 'package:shared_preferences/shared_preferences.dart';

/// 달력 Filter에서 선택한 토픽 목록을 로컬에 저장한다.
/// 값이 저장되어 있지 않으면(키 없음) "아무것도 선택 안 함" 상태를 의미하며,
/// 이 경우 필터는 적용되지 않고(전체 토픽 조회) UI 체크박스도 비어 있다.
class TopicFilterStorage {
  static const String _selectedTopicIdsKey = 'selected_topic_ids';

  final SharedPreferences _prefs;

  TopicFilterStorage(this._prefs);

  static Future<TopicFilterStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TopicFilterStorage(prefs);
  }

  Set<int>? getSelectedTopicIds() {
    final stored = _prefs.getStringList(_selectedTopicIdsKey);
    if (stored == null) return null;
    return stored.map(int.parse).toSet();
  }

  Future<void> saveSelectedTopicIds(Set<int>? topicIds) async {
    if (topicIds == null) {
      await _prefs.remove(_selectedTopicIdsKey);
    } else {
      await _prefs.setStringList(
        _selectedTopicIdsKey,
        topicIds.map((id) => id.toString()).toList(),
      );
    }
  }
}
