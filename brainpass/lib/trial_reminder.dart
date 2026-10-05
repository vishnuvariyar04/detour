// trial_reminder.dart
//
// The one notification the paywall promises: "your free trial ends tomorrow",
// shown the day before billing starts. Android's counterpart of the iOS app's
// FamilyControls.scheduleTrialReminder.
//
// It goes to the PARENT's phone, about the parent's own subscription, and is
// the only notification of its kind. Nothing about the child is in it. It is
// scheduled locally, so no server or push service is involved.
//
// Fail-safe like everything around payments: any error is swallowed, because a
// reminder that could not be scheduled must never block a purchase.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class TrialReminder {
  // Not 4201: that is GuardService's foreground notification, and reusing it
  // would replace the lock's own notification.
  static const _id = 7301;
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<bool> _init() async {
    if (_ready) return true;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[trial reminder] init failed: $e');
    }
    return _ready;
  }

  /// Schedule the reminder for 10:00 local time on the day before [billing].
  /// If that moment has already passed (a very short trial), it is skipped.
  static Future<void> schedule(DateTime billing) async {
    if (!await _init()) return;
    try {
      final dayBefore = DateTime(billing.year, billing.month, billing.day - 1, 10);
      if (!dayBefore.isAfter(DateTime.now())) return;
      await _plugin.zonedSchedule(
        id: _id,
        // An absolute moment, so UTC is exact whatever the phone's time zone.
        scheduledDate: tz.TZDateTime.from(dayBefore, tz.UTC),
        title: 'Your Nupo free trial ends tomorrow',
        body: 'Nothing to do if you want to keep learning. To cancel, open '
            'Google Play → Subscriptions before tomorrow.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'trial_reminder',
            'Trial reminder',
            channelDescription:
                'One reminder the day before a free trial turns into a payment.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // Inexact is fine for a reminder a day ahead, and needs no
        // exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[trial reminder] schedule failed: $e');
    }
  }

  /// Ask for notification permission (Android 13+). True when allowed.
  static Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    } catch (_) {
      return false;
    }
  }
}
