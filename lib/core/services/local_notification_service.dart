import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:huddle/core/models/scheduled_notification_model.dart';
import 'package:huddle/core/services/notification_deep_link_router.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _androidChannelId = 'reminders_channel';

/// Owns the on-device [FlutterLocalNotificationsPlugin] instance that turns whatever
/// [NotificationScheduleService.fetchSchedule] returns into actual device notifications.
/// This app has no push transport (see `docs/NOTIFICATIONS_BACKEND_REQUIREMENTS.md`) - every
/// notification the user sees is scheduled here, locally, ahead of time.
class LocalNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final localTimezone = await getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      'Reminders',
      description: 'Journal, task, and expense reminders',
      importance: Importance.high,
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// The device's current IANA time zone (e.g. "Asia/Kolkata") - kept in sync with the
  /// backend by [NotificationPreferencesProvider] so `scheduledAt` times it computes for
  /// journal/expense reminders land on the user's actual wall-clock time.
  Future<String> getLocalTimezone() => FlutterTimezone.getLocalTimezone();

  /// Handles the case where the app was launched by tapping a notification while fully
  /// terminated - the local-notification equivalent of `getInitialMessage()` for FCM.
  Future<Map<String, dynamic>?> consumeLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return _decodePayload(details?.notificationResponse?.payload);
  }

  /// Replaces every currently-scheduled reminder with [items]. Cancel-all-then-reschedule-all
  /// (rather than diffing against what's already pending) is intentional: the schedule is
  /// short-lived and re-fetched on every app launch/resume anyway, so diffing would add
  /// complexity for no real benefit.
  Future<void> scheduleAll(List<ScheduledNotificationModel> items) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final item in items) {
      final scheduledDate = tz.TZDateTime.from(item.scheduledAt, tz.local);
      if (!scheduledDate.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        _stableId(item.id),
        item.title,
        item.body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(_androidChannelId, 'Reminders', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(item.data),
      );
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = _decodePayload(response.payload);
    if (payload != null) notificationDeepLinkRouter.handleTapPayload(payload);
  }

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null) return null;
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  /// flutter_local_notifications ids are 32-bit ints, but schedule ids from the backend are
  /// stable strings (see the backend contract) - hash to a stable positive int so the same
  /// logical reminder always maps to the same notification id across fetches.
  int _stableId(String id) => id.hashCode & 0x7fffffff;
}

final localNotificationService = LocalNotificationService();
