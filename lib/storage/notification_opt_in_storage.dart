import 'package:shared_preferences/shared_preferences.dart';

/// Share 탭 최초 진입 시 띄우는 인앱 알림 opt-in 다이얼로그에 대한
/// 사용자의 응답을 로컬에 기록한다.
///
/// 한 번 응답하면(수락이든 거절이든) 다시 띄우지 않는다. 이후에는
/// 설정 화면의 알림 토글로만 상태를 바꾼다.
class NotificationOptInStorage {
  static const String _respondedKey = 'notification_opt_in_responded';
  static const String _optedInKey = 'notification_opt_in_accepted';

  final SharedPreferences _prefs;

  NotificationOptInStorage(this._prefs);

  static Future<NotificationOptInStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationOptInStorage(prefs);
  }

  /// opt-in 다이얼로그에 이미 응답했는지 여부.
  bool get hasResponded => _prefs.getBool(_respondedKey) ?? false;

  /// opt-in 다이얼로그에서 "허용"을 선택했는지 여부.
  bool get optedIn => _prefs.getBool(_optedInKey) ?? false;

  Future<void> saveResponse({required bool optedIn}) async {
    await _prefs.setBool(_respondedKey, true);
    await _prefs.setBool(_optedInKey, optedIn);
  }

  /// 로그아웃/회원탈퇴 시 호출 — 같은 기기의 다음 사용자에게 다시
  /// opt-in을 물어볼 수 있도록 응답 기록을 지운다.
  Future<void> reset() async {
    await _prefs.remove(_respondedKey);
    await _prefs.remove(_optedInKey);
  }
}
