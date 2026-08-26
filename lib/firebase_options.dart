// Firebase 프로젝트 "sharable-piggy"의 플랫폼별 설정값.
//
// android/app/google-services.json, ios/Runner/GoogleService-Info.plist에서
// 값을 그대로 옮겨 적었다 (두 파일 모두 API 키를 담고 있어 .gitignore 처리됨,
// 이 파일은 커밋해도 되는 값들만 담고 있다 — Google 공식 문서상 이 키들은
// 클라이언트 앱에 어차피 번들되므로 비밀로 취급하지 않는다).
//
// flutterfire CLI 없이 수동으로 작성했으므로, Firebase 콘솔에서 앱 설정이
// 바뀌면 (예: 새 플랫폼 추가) 이 파일도 같이 갱신해야 한다.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDduLspfSR1afbtgBgNu4hiygSQ36w6xOQ',
    appId: '1:783938606545:android:051caf05af1f51b28c3cf0',
    messagingSenderId: '783938606545',
    projectId: 'sharable-piggy',
    storageBucket: 'sharable-piggy.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSzg__7vuqFm7VL3nWbM0tSWGPwLL03Jc',
    appId: '1:783938606545:ios:f738c52298decb918c3cf0',
    messagingSenderId: '783938606545',
    projectId: 'sharable-piggy',
    storageBucket: 'sharable-piggy.firebasestorage.app',
    iosBundleId: 'com.sharablepiggy.app',
  );
}
