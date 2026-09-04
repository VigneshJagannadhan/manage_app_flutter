import 'package:huddle/core/constants/app_urls.dart';
import 'package:huddle/core/models/scheduled_notification_model.dart';
import 'package:huddle/core/services/api_result.dart';
import 'package:huddle/core/services/api_services.dart';

/// Client for the backend contract documented in
/// `docs/NOTIFICATIONS_BACKEND_REQUIREMENTS.md`.
///
/// `GET /notifications/schedule` returns the reminders currently due for the signed-in
/// user - already filtered by their notification preferences - as a "here's what to show"
/// list. The backend owns all the "already journaled/logged an expense today?" and
/// task-due-date logic; this app only fetches the result and schedules it locally via
/// [LocalNotificationService].
class NotificationScheduleServiceException implements Exception {
  NotificationScheduleServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotificationScheduleService {
  NotificationScheduleService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<List<ScheduledNotificationModel>> fetchSchedule() async {
    final result = await _api.get<List<ScheduledNotificationModel>>(
      AppUrls.notificationSchedule,
      parser: (data) => ((data as Map<String, dynamic>)['notifications'] as List<dynamic>)
          .map((item) => ScheduledNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw NotificationScheduleServiceException(failure.message));
  }
}

final notificationScheduleService = NotificationScheduleService();
