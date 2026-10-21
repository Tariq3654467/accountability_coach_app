import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationService local, required PushService push})
      : _local = local,
        _push = push;

  final NotificationService _local;
  final PushService _push;

  bool _permissionGranted = false;
  bool _pushStarted = false;
  String? _pushToken;
  StreamSubscription<String>? _tokenSub;

  bool get isSupported => _local.isSupported;
  bool get permissionGranted => _permissionGranted;
  bool get pushReady => _push.isReady;
  String? get pushToken => _pushToken;

  /// Safe to call more than once; the service ignores repeat init.
  Future<void> init() async {
    await _local.init();
    notifyListeners();
  }

  /// Asks the OS for permission. Existing reminders were already scheduled by GoalProvider.
  Future<bool> enableReminders() async {
    _permissionGranted = await _local.requestPermission();
    notifyListeners();
    return _permissionGranted;
  }

  /// Starts FCM. [onToken] fires with the first token and every refresh.
  /// Returns null when push is unavailable (web, no Firebase config, or denied).
  Future<String?> initPush({required void Function(String token) onToken}) async {
    if (_pushStarted) return _pushToken;
    _pushStarted = true;

    _push.onForegroundMessage = (title, body) => _local.showNow(title, body);
    final token = await _push.init();
    _pushToken = token;
    if (token != null) onToken(token);

    await _tokenSub?.cancel();
    _tokenSub = _push.onTokenChanged.listen((t) {
      _pushToken = t;
      onToken(t);
      notifyListeners();
    });

    notifyListeners();
    return token;
  }

  Future<void> sendTestNotification() =>
      _local.showNow('Accountability Coach', 'Notifications are working.');

  @override
  void dispose() {
    _tokenSub?.cancel();
    super.dispose();
  }
}
