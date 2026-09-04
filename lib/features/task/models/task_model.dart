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
    this.description,
    required this.priority,
    this.status = TaskStatus.open,
    this.createdAt,
    this.dueDate,
    this.groupId,
    this.createdBy,
    this.assignedTo,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriorityApi.fromApiValue(json['priority'] as String),
      // Falls back to `open` for responses from before the backend added this field.
      status: json['status'] != null ? TaskStatusApi.fromApiValue(json['status'] as String) : TaskStatus.open,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
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
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority!.apiValue,
      if (status != null) 'status': status!.apiValue,
      if (createdAt != null) 'createdAt': createdAt!.toServer(),
      if (dueDate != null) 'dueDate': dueDate!.toServer(),
      if (groupId != null) 'groupId': groupId,
      if (assignedTo != null) 'assignedTo': assignedTo,
    };
  }

  /// Full-fidelity serialization for the local cache - mirrors [fromJson]'s wire shape
  /// (unlike [toJson], which is a create-request body and omits server-assigned fields
  /// like `_id`/`createdBy`). Decode with [fromJson] unchanged.
  Map<String, dynamic> toCacheJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'priority': priority?.apiValue,
      'status': status?.apiValue,
      'createdAt': createdAt?.toServer(),
      'dueDate': dueDate?.toServer(),
      'groupId': groupId,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
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
