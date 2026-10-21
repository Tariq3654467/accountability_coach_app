import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Must be top-level. Register in main.dart with
/// FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushService {
  bool _ready = false;
  bool get isReady => _ready;

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenChanged => _tokenController.stream;

  /// Called with (title, body) for messages received while the app is open.
  void Function(String title, String body)? onForegroundMessage;

  /// Returns the FCM token, or null if push is unavailable (web, no Firebase config, denied).
  Future<String?> init() async {
    if (kIsWeb) return null;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n != null) onForegroundMessage?.call(n.title ?? '', n.body ?? '');
      });
      messaging.onTokenRefresh.listen(_tokenController.add);

      _ready = true;
      return await messaging.getToken();
    } catch (_) {
      _ready = false;
      return null;
    }
  }
}
