import 'package:shared_preferences/shared_preferences.dart';

/// 지출/수입을 추가할 때 마지막으로 선택한 토픽을 로컬에 저장한다.
/// 다음 항목을 추가할 때 기본 선택값으로 쓰인다.
class LastUsedTopicStorage {
  static const String _lastUsedTopicIdKey = 'last_used_topic_id';

  final SharedPreferences _prefs;

  LastUsedTopicStorage(this._prefs);

  static Future<LastUsedTopicStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LastUsedTopicStorage(prefs);
  }

  int? getLastUsedTopicId() => _prefs.getInt(_lastUsedTopicIdKey);

  Future<void> saveLastUsedTopicId(int topicId) =>
      _prefs.setInt(_lastUsedTopicIdKey, topicId);
}
