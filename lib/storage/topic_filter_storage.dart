import 'package:shared_preferences/shared_preferences.dart';

import '../models/topic_filter.dart';

/// 달력 Filter에서 선택한 토픽 범위를 로컬에 저장한다.
/// 아무것도 저장돼 있지 않으면 [TopicFilterAll](기본값)로 취급한다.
class TopicFilterStorage {
  static const String _modeKey = 'topic_filter_mode';
  static const String _selectedTopicIdsKey = 'selected_topic_ids';

  final SharedPreferences _prefs;

  TopicFilterStorage(this._prefs);

  static Future<TopicFilterStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TopicFilterStorage(prefs);
  }

  TopicFilter getFilter() {
    switch (_prefs.getString(_modeKey)) {
      case 'none':
        return const TopicFilterNone();
      case 'selected':
        final stored = _prefs.getStringList(_selectedTopicIdsKey) ?? const [];
        return TopicFilterSelected(stored.map(int.parse).toSet());
      default:
        return const TopicFilterAll();
    }
  }

  Future<void> saveFilter(TopicFilter filter) async {
    switch (filter) {
      case TopicFilterAll():
        await _prefs.remove(_modeKey);
        await _prefs.remove(_selectedTopicIdsKey);
      case TopicFilterNone():
        await _prefs.setString(_modeKey, 'none');
        await _prefs.remove(_selectedTopicIdsKey);
      case TopicFilterSelected(:final topicIds):
        await _prefs.setString(_modeKey, 'selected');
        await _prefs.setStringList(
          _selectedTopicIdsKey,
          topicIds.map((id) => id.toString()).toList(),
        );
    }
  }
}
