import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

class DeepLinkService {
  final AppLinks _appLinks;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  Future<Uri?> getInitialUri() async {
    final appLink = await _appLinks.getInitialLink();
    debugPrint('[DeepLinkService] getInitialUri: $appLink');
    final message =
        await FirebaseMessaging.instance.getInitialMessage().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('[DeepLinkService] getInitialMessage TIMEOUT');
        return null;
      },
    );
    debugPrint('[DeepLinkService] getInitialUri done: $message');
    return appLink ?? _uriFromMessage(message);
  }

  Stream<Uri> get uriStream {
    late final StreamController<Uri> controller;
    StreamSubscription<Uri>? appLinkSubscription;
    StreamSubscription<RemoteMessage>? notificationSubscription;

    controller = StreamController<Uri>(
      onListen: () {
        debugPrint('[DeepLinkService] onListen');
        appLinkSubscription = _appLinks.uriLinkStream.listen(
          controller.add,
          onError: controller.addError,
        );
        notificationSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
          (message) {
            debugPrint('[DeepLinkService] onMessageOpenedApp: $message');
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
