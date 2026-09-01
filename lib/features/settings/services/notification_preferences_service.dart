import 'package:huddle/core/constants/app_urls.dart';
import 'package:huddle/core/services/api_result.dart';
import 'package:huddle/core/services/api_services.dart';
import 'package:huddle/features/settings/models/notification_preferences_model.dart';

class NotificationPreferencesServiceException implements Exception {
  NotificationPreferencesServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotificationPreferencesService {
  NotificationPreferencesService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<NotificationPreferencesModel> getPreferences() async {
    final result = await _api.get<NotificationPreferencesModel>(
      AppUrls.notificationPreferences,
      parser: (data) => NotificationPreferencesModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<NotificationPreferencesModel> updatePreferences({
    bool? generalRemindersEnabled,
    bool? journalReminderEnabled,
    bool? taskReminderEnabled,
    bool? expenseRemindersEnabled,
    String? journalReminderTime,
    String? expenseReminderTime,
  }) async {
    final result = await _api.patch<NotificationPreferencesModel>(
      AppUrls.notificationPreferences,
      data: {
        'generalRemindersEnabled': ?generalRemindersEnabled,
        'journalReminderEnabled': ?journalReminderEnabled,
        'taskReminderEnabled': ?taskReminderEnabled,
        'expenseReminderEnabled': ?expenseRemindersEnabled,
        'journalReminderTime': ?journalReminderTime,
        'expenseReminderTime': ?expenseReminderTime,
      },
      parser: (data) => NotificationPreferencesModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw NotificationPreferencesServiceException(failure.message));
  }
}

final notificationPreferencesService = NotificationPreferencesService();
