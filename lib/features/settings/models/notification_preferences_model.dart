class NotificationPreferencesModel {
  NotificationPreferencesModel({
    this.generalRemindersEnabled = true,
    this.journalReminderEnabled = true,
    this.taskReminderEnabled = true,
    this.expenseRemindersEnabled = true,
    this.journalReminderTime,
    this.expenseReminderTime,
    this.timezone,
  });

  final bool generalRemindersEnabled;
  final bool journalReminderEnabled;
  final bool taskReminderEnabled;
  final bool expenseRemindersEnabled;
  // "HH:mm", 24h. No equivalent field for general (ad hoc) or task (due-date driven) reminders.
  final String? journalReminderTime;
  final String? expenseReminderTime;
  // IANA time zone name (e.g. "Asia/Kolkata") the backend uses to interpret the reminder times
  // above. Kept in sync with the device's zone by [NotificationPreferencesProvider].
  final String? timezone;

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      generalRemindersEnabled: json['generalRemindersEnabled'] as bool? ?? true,
      journalReminderEnabled: json['journalReminderEnabled'] as bool? ?? true,
      taskReminderEnabled: json['taskReminderEnabled'] as bool? ?? true,
      expenseRemindersEnabled: json['expenseReminderEnabled'] as bool? ?? true,
      journalReminderTime: json['journalReminderTime'] as String?,
      expenseReminderTime: json['expenseReminderTime'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  NotificationPreferencesModel copyWith({
    bool? generalRemindersEnabled,
    bool? journalReminderEnabled,
    bool? taskReminderEnabled,
    bool? expenseRemindersEnabled,
    String? journalReminderTime,
    String? expenseReminderTime,
    String? timezone,
  }) {
    return NotificationPreferencesModel(
      generalRemindersEnabled: generalRemindersEnabled ?? this.generalRemindersEnabled,
      journalReminderEnabled: journalReminderEnabled ?? this.journalReminderEnabled,
      taskReminderEnabled: taskReminderEnabled ?? this.taskReminderEnabled,
      expenseRemindersEnabled: expenseRemindersEnabled ?? this.expenseRemindersEnabled,
      journalReminderTime: journalReminderTime ?? this.journalReminderTime,
      expenseReminderTime: expenseReminderTime ?? this.expenseReminderTime,
      timezone: timezone ?? this.timezone,
    );
  }
}
