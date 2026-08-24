import 'package:huddle/core/extensions/date_time_extensions.dart';

class JournalEntryModel {
  final String? id;
  final DateTime date;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JournalEntryModel({this.id, required this.date, required this.content, this.createdAt, this.updatedAt});

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['_id'] as String?,
      date: DateTime.parse(json['date'] as String).atMidnight,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}
