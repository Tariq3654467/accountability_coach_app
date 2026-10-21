import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/enums.dart';
import '../models/dashboard_state.dart';
import '../models/goal.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool get isSupported => !kIsWeb;

  static const _maxSlots = 16;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'goal_reminders',
      'Goal reminders',
      channelDescription: 'Reminders to check in on your goals',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (!isSupported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // tz.local stays UTC; reminders still fire, just offset.
    }
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    if (!isSupported || !_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted =
          await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return (granted ?? iosGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  int _baseId(String goalId) => (goalId.hashCode & 0x1FFFFF) * 32;

  String _message(Goal g, int slot, int total) {
    switch (g.reminderStyle) {
      case ReminderStyle.gentle:
        return 'A small step on "${g.name}" keeps you moving.';
      case ReminderStyle.persistent:
        return 'Check in now: "${g.name}" is waiting on you.';
      case ReminderStyle.escalating:
        final f = total <= 1 ? 0.0 : slot / (total - 1);
        if (f < 0.34) return 'Time to start on "${g.name}".';
        if (f < 0.75) return 'Still open: "${g.name}". Get it done today.';
        return 'Last call today for "${g.name}". Don\'t skip it!';
      case ReminderStyle.encouraging:
        return 'You are making progress on "${g.name}". Keep going at your own pace.';
      case ReminderStyle.none:
        return '';
    }
  }

  tz.TZDateTime _nextAt(int hour, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var day = 0;
    while (true) {
      final d = tz.TZDateTime(tz.local, now.year, now.month, now.day + day, hour);
      final weekdayOk = weekday == null || d.weekday == weekday;
      if (weekdayOk && d.isAfter(now)) return d;
      day++;
    }
  }

  Future<void> scheduleForGoal(
    Goal g, {
    ReminderPreferences preferences = const ReminderPreferences(),
  }) async {
    if (!isSupported || !_ready) return;
    await cancelForGoal(g.id);
    if (g.status != 'active' ||
        !preferences.notificationsEnabled ||
        g.reminderStyle == ReminderStyle.none) {
      return;
    }

    final base = _baseId(g.id);
    try {
      final parts = preferences.reminderTime.split(':').map(int.tryParse).toList();
      final hour = parts.isNotEmpty ? parts[0] ?? 9 : 9;
      final minute = parts.length > 1 ? parts[1] ?? 0 : 0;
      var index = 0;
      for (final milestone in g.allMilestones) {
        if (milestone.done || index >= _maxSlots) continue;
        final due = milestone.dueDate;
        var scheduled = tz.TZDateTime(
          tz.local,
          due.year,
          due.month,
          due.day,
          hour.clamp(0, 23),
          minute.clamp(0, 59),
        );
        final now = tz.TZDateTime.now(tz.local);
        final recurring = milestone.tier == Tier.daily;
        if (recurring && scheduled.isBefore(now)) {
          scheduled = _nextAt(hour.clamp(0, 23));
        } else if (!recurring && scheduled.isBefore(now)) {
          scheduled = now.add(const Duration(minutes: 1));
        }
        await _plugin.zonedSchedule(
          base + index,
          g.name,
          _message(g, index, g.totalCount),
          scheduled,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: recurring ? DateTimeComponents.time : null,
        );
        index++;
      }
    } catch (_) {}
  }

  Future<void> scheduleDailyCheckIns(ReminderPreferences preferences) async {
    if (!isSupported || !_ready) return;
    const startId = 2147483001;
    const endId = 2147483002;
    await _plugin.cancel(startId);
    await _plugin.cancel(endId);
    if (!preferences.dailyCheckInsEnabled) return;
    final start = _parseTime(preferences.dayStartTime);
    final end = _parseTime(preferences.dayEndTime);
    final now = tz.TZDateTime.now(tz.local);
    final checkIns = [
      (id: startId, time: start, title: 'A fresh start', body: 'Choose one small step for today.'),
      (id: endId, time: end, title: 'Your day in review', body: 'Notice what went well and plan a kind next step.'),
    ];
    for (final checkIn in checkIns) {
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, checkIn.time.$1, checkIn.time.$2);
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        checkIn.id,
        checkIn.title,
        checkIn.body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  (int, int) _parseTime(String value) {
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.length != 2 || parts[0] == null || parts[1] == null) return (9, 0);
    return (parts[0]!.clamp(0, 23), parts[1]!.clamp(0, 59));
  }

  Future<void> cancelForGoal(String goalId) async {
    if (!isSupported || !_ready) return;
    final base = _baseId(goalId);
    for (var i = 0; i < _maxSlots; i++) {
      try {
        await _plugin.cancel(base + i);
      } catch (_) {}
    }
  }

  Future<void> cancelAll() async {
    if (!isSupported || !_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> showNow(String title, String body) async {
    if (!isSupported || !_ready) return;
    try {
      await _plugin.show(
          DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF, title, body, _details);
    } catch (_) {}
  }
}
