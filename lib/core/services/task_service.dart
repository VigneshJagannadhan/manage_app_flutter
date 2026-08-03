import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/services/api_result.dart';
import 'package:manage_app/core/services/api_services.dart';
import 'package:manage_app/features/task/models/task_model.dart';

class TaskServiceException implements Exception {
  TaskServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TaskService {
  TaskService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<TaskModel?> createTask(TaskModel task) async {
    final result = await _api.post<TaskModel>(
      AppUrls.tasks,
      data: {
        'title': task.title,
        'description': task.description,
        'priority': task.priority?.apiValue,
        'groupId': task.groupId,
        if (task.createdAt != null) 'createdAt': task.createdAt?.toIso8601String(),
        if (task.dueDate != null) 'dueDate': task.dueDate?.toIso8601String(),
        if (task.assignedTo != null) 'assignedTo': task.assignedTo,
      },
      parser: (data) => TaskModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
  }) async {
    final result = await _api.patch<TaskModel>(
      '${AppUrls.tasks}/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (priority != null) 'priority': priority.apiValue,
        if (status != null) 'status': status.apiValue,
        if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
      parser: (data) => TaskModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<void> deleteTask({required String id}) async {
    final result = await _api.delete<void>('${AppUrls.tasks}/$id', parser: (_) {});
    return _unwrap(result);
  }

  /// [groupId] omitted fetches tasks across every group the caller belongs to.
  Future<List<TaskModel>> listTasks({TaskStatus? status, String? groupId}) async {
    final result = await _api.get<List<TaskModel>>(
      AppUrls.tasks,
      queryParameters: {if (status != null) 'status': status.apiValue, if (groupId != null) 'groupId': groupId},
      parser: (data) => (data as List<dynamic>).map((task) => TaskModel.fromJson(task as Map<String, dynamic>)).toList(),
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw TaskServiceException(failure.message));
  }
}

final taskService = TaskService();
