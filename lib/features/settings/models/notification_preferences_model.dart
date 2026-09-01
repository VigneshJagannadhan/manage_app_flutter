class NotificationPreferencesModel {
  NotificationPreferencesModel({
    this.generalRemindersEnabled = true,
    this.journalReminderEnabled = true,
    this.taskReminderEnabled = true,
    this.expenseRemindersEnabled = true,
    this.journalReminderTime,
    this.expenseReminderTime,
  });

  final bool generalRemindersEnabled;
  final bool journalReminderEnabled;
  final bool taskReminderEnabled;
  final bool expenseRemindersEnabled;
  // "HH:mm", 24h. No equivalent field for general (ad hoc) or task (due-date driven) reminders.
  final String? journalReminderTime;
  final String? expenseReminderTime;

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      generalRemindersEnabled: json['generalRemindersEnabled'] as bool? ?? true,
      journalReminderEnabled: json['journalReminderEnabled'] as bool? ?? true,
      taskReminderEnabled: json['taskReminderEnabled'] as bool? ?? true,
      expenseRemindersEnabled: json['expenseReminderEnabled'] as bool? ?? true,
      journalReminderTime: json['journalReminderTime'] as String?,
      expenseReminderTime: json['expenseReminderTime'] as String?,
    );
  }

  NotificationPreferencesModel copyWith({
    bool? generalRemindersEnabled,
    bool? journalReminderEnabled,
    bool? taskReminderEnabled,
    bool? expenseRemindersEnabled,
    String? journalReminderTime,
    String? expenseReminderTime,
  }) {
    return NotificationPreferencesModel(
      generalRemindersEnabled: generalRemindersEnabled ?? this.generalRemindersEnabled,
      journalReminderEnabled: journalReminderEnabled ?? this.journalReminderEnabled,
      taskReminderEnabled: taskReminderEnabled ?? this.taskReminderEnabled,
      expenseRemindersEnabled: expenseRemindersEnabled ?? this.expenseRemindersEnabled,
      journalReminderTime: journalReminderTime ?? this.journalReminderTime,
      expenseReminderTime: expenseReminderTime ?? this.expenseReminderTime,
    );
  }
}
