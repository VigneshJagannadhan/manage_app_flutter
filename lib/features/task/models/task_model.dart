import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';

class TaskModel {
  final String? id;
  final String? title;
  final String? description;
  final TaskPriority? priority;
  final TaskStatus? status;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final String? groupId;
  final String? createdBy;
  // A member's userId. Defaults to the creator server-side when omitted.
  final String? assignedTo;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.status = TaskStatus.open,
    required this.createdAt,
    this.dueDate,
    this.groupId,
    this.createdBy,
    this.assignedTo,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: TaskPriorityApi.fromApiValue(json['priority'] as String),
      // Falls back to `open` for responses from before the backend added this field.
      status: json['status'] != null ? TaskStatusApi.fromApiValue(json['status'] as String) : TaskStatus.open,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      groupId: json['groupId'] as String?,
      createdBy: json['createdBy'] as String?,
      assignedTo: json['assignedTo'] as String?,
    );
  }

  /// Serializes for the create-task request body. `id`/`createdBy` are server-assigned and omitted.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (priority != null) 'priority': priority!.apiValue,
      if (status != null) 'status': status!.apiValue,
      if (createdAt != null) 'createdAt': createdAt!.toServer(),
      if (dueDate != null) 'dueDate': dueDate!.toServer(),
      if (groupId != null) 'groupId': groupId,
      if (assignedTo != null) 'assignedTo': assignedTo,
    };
  }

  TaskModel copyWith({TaskStatus? status}) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      dueDate: dueDate,
      groupId: groupId,
      createdBy: createdBy,
      assignedTo: assignedTo,
    );
  }
}
