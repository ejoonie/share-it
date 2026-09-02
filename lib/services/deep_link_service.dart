import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DeepLinkService {
  final AppLinks _appLinks;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  Future<Uri?> getInitialUri() async {
    final appLink = await _appLinks.getInitialLink();
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return appLink ?? _uriFromMessage(message);
  }

  Stream<Uri> get uriStream {
    late final StreamController<Uri> controller;
    StreamSubscription<Uri>? appLinkSubscription;
    StreamSubscription<RemoteMessage>? notificationSubscription;

    controller = StreamController<Uri>(
      onListen: () {
        appLinkSubscription = _appLinks.uriLinkStream.listen(
          controller.add,
          onError: controller.addError,
        );
        notificationSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
          (message) {
            final uri = _uriFromMessage(message);
            if (uri != null) controller.add(uri);
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await appLinkSubscription?.cancel();
        await notificationSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Uri? _uriFromMessage(RemoteMessage? message) {
    final value = message?.data['deeplink'];
    if (value is! String) return null;
    return Uri.tryParse(value);
  }
}
