import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/services/task_service.dart';
import 'package:huddle/features/task/models/task_model.dart';

/// Read-through cache for the account's tasks - pure data access (fetch remote, mirror to
/// [cache]), no scheduling/retry policy. That lives in [TaskProvider]; mirrors the role
/// [JournalRepository] plays for journal drafts.
class TaskRepository {
  TaskRepository({required this.remote, required this.cache});

  final TaskService remote;
  final JsonCache cache;

  static const _key = 'tasks';

  List<TaskModel> cachedTasks() => cache.getList(_key, TaskModel.fromJson);

  Future<List<TaskModel>> syncTasks({TaskStatus? status, String? groupId}) async {
    final tasks = await remote.listTasks(status: status, groupId: groupId);
    await cache.setList(_key, tasks.map((task) => task.toCacheJson()).toList());
    return tasks;
  }
}
