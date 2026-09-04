import 'dart:async';

import 'package:huddle/core/providers/notification_schedule_provider.dart';
import 'package:huddle/core/services/local_notification_service.dart';
import 'package:huddle/features/settings/models/notification_preferences_model.dart';
import 'package:huddle/features/settings/services/notification_preferences_service.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

class NotificationPreferencesProvider extends BaseProvider {
  NotificationPreferencesProvider({
    required this.notificationPreferencesService,
    required this.notificationScheduleProvider,
    required this.localNotificationService,
  });

  final NotificationPreferencesService notificationPreferencesService;
  final NotificationScheduleProvider notificationScheduleProvider;
  final LocalNotificationService localNotificationService;

  @override
  void onInit() {}

  @override
  void onDispose() {}

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationPreferencesModel? _preferences;
  NotificationPreferencesModel? get preferences => _preferences;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadPreferences() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _preferences = await notificationPreferencesService.getPreferences();
    } on NotificationPreferencesServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    unawaited(_syncTimezoneIfNeeded());
  }

  /// The backend computes reminder-time `scheduledAt` instants using this stored zone (see
  /// `NOTIFICATIONS_BACKEND_REQUIREMENTS.md`). Keep it current so a user who travels, or whose
  /// zone was never recorded, still gets reminders at the right local wall-clock time.
  Future<void> _syncTimezoneIfNeeded() async {
    final current = _preferences;
    if (current == null) return;
    final deviceTimezone = await localNotificationService.getLocalTimezone();
    if (current.timezone == deviceTimezone) return;

    try {
      _preferences = await notificationPreferencesService.updatePreferences(timezone: deviceTimezone);
      notifyListeners();
    } on NotificationPreferencesServiceException {
      // Best-effort: the next launch/resume will retry.
    }
  }

  Future<void> setGeneralRemindersEnabled(bool enabled) => _update(generalRemindersEnabled: enabled);

  Future<void> setJournalReminderEnabled(bool enabled) => _update(journalReminderEnabled: enabled);

  Future<void> setTaskReminderEnabled(bool enabled) => _update(taskReminderEnabled: enabled);

  Future<void> setExpenseRemindersEnabled(bool enabled) => _update(expenseRemindersEnabled: enabled);

  Future<void> setJournalReminderTime(String time) => _update(journalReminderTime: time);

  Future<void> setExpenseReminderTime(String time) => _update(expenseReminderTime: time);

  Future<void> _update({
    bool? generalRemindersEnabled,
    bool? journalReminderEnabled,
    bool? taskReminderEnabled,
    bool? expenseRemindersEnabled,
    String? journalReminderTime,
    String? expenseReminderTime,
  }) async {
    final previous = _preferences;
    if (previous == null) return;

    _preferences = previous.copyWith(
      generalRemindersEnabled: generalRemindersEnabled,
      journalReminderEnabled: journalReminderEnabled,
      taskReminderEnabled: taskReminderEnabled,
      expenseRemindersEnabled: expenseRemindersEnabled,
      journalReminderTime: journalReminderTime,
      expenseReminderTime: expenseReminderTime,
    );
    _errorMessage = null;
    notifyListeners();

    try {
      _preferences = await notificationPreferencesService.updatePreferences(
        generalRemindersEnabled: generalRemindersEnabled,
        journalReminderEnabled: journalReminderEnabled,
        taskReminderEnabled: taskReminderEnabled,
        expenseRemindersEnabled: expenseRemindersEnabled,
        journalReminderTime: journalReminderTime,
        expenseReminderTime: expenseReminderTime,
      );
      unawaited(notificationScheduleProvider.refresh());
    } on NotificationPreferencesServiceException catch (e) {
      _preferences = previous;
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }
}
