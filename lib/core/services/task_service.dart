import 'package:huddle/core/constants/app_urls.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/services/api_result.dart';
import 'package:huddle/core/services/api_services.dart';
import 'package:huddle/features/task/models/task_model.dart';

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
        if (task.createdAt != null) 'createdAt': task.createdAt?.toServer(),
        if (task.dueDate != null) 'dueDate': task.dueDate?.toServer(),
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
        'title': ?title,
        'description': ?description,
        'priority': ?priority?.apiValue,
        'status': ?status?.apiValue,
        'createdAt': ?createdAt?.toServer(),
        'dueDate': ?dueDate?.toServer(),
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
      queryParameters: {'status': ?status?.apiValue, 'groupId': ?groupId},
      parser: (data) => (data as List<dynamic>).map((task) => TaskModel.fromJson(task as Map<String, dynamic>)).toList(),
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw TaskServiceException(failure.message));
  }
}

final taskService = TaskService();
