enum ScheduledNotificationType { journal, task, expense, general }

extension ScheduledNotificationTypeApi on String {
  ScheduledNotificationType toScheduledNotificationType() {
    return ScheduledNotificationType.values.firstWhere(
      (type) => type.name == this,
      orElse: () => ScheduledNotificationType.general,
    );
  }
}

class ScheduledNotificationModel {
  ScheduledNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.data,
  });

  final String id;
  final ScheduledNotificationType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final Map<String, dynamic> data;

  factory ScheduledNotificationModel.fromJson(Map<String, dynamic> json) {
    return ScheduledNotificationModel(
      id: json['id'] as String,
      type: (json['type'] as String).toScheduledNotificationType(),
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
