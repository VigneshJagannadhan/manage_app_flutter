import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/data/mutation_store.dart';
import 'package:huddle/core/data/pending_mutation.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/services/task_service.dart';
import 'package:huddle/features/task/models/task_model.dart';

/// Read-through cache and pending-mutation data access for the account's tasks - pure data
/// access (fetch remote, mirror to [cache]/[mutations]), no scheduling/retry policy. That
/// lives in [TaskProvider]; mirrors the role [JournalRepository] plays for journal drafts.
class TaskRepository {
  TaskRepository({required this.remote, required this.cache, MutationStore? mutations}) : mutations = mutations ?? mutationStore;

  final TaskService remote;
  final JsonCache cache;
  final MutationStore mutations;

  static const _key = 'tasks';
  static const entityType = 'task';

  List<TaskModel> cachedTasks() => applyPendingOverlay(cache.getList(_key, TaskModel.fromJson));

  Future<List<TaskModel>> syncTasks({TaskStatus? status, String? groupId}) async {
    final tasks = await remote.listTasks(status: status, groupId: groupId);
    await cache.setList(_key, tasks.map((task) => task.toCacheJson()).toList());
    return applyPendingOverlay(tasks);
  }

  /// Applies every still-pending local mutation on top of [serverList] so an
  /// offline-created/edited/deleted task survives being overwritten by a fresher
  /// cache/network read that predates it (app restart before a flush lands,
  /// pull-to-refresh, a filter/group-scope change while a flush is still in flight).
  List<TaskModel> applyPendingOverlay(List<TaskModel> serverList) {
    final pending = mutations.allFor(entityType);
    if (pending.isEmpty) return serverList;

    final byId = {for (final mutation in pending) mutation.entityId: mutation};
    final overlaid = <TaskModel>[];
    for (final task in serverList) {
      final mutation = task.id == null ? null : byId[task.id];
      if (mutation == null) {
        overlaid.add(task);
      } else if (mutation.op != MutationOp.delete) {
        overlaid.add(TaskModel.fromJson(mutation.payload!));
      }
      // op == delete: drop the item entirely.
    }

    final presentIds = overlaid.map((task) => task.id).whereType<String>().toSet();
    for (final mutation in pending) {
      if (mutation.op == MutationOp.create && !presentIds.contains(mutation.entityId)) {
        overlaid.add(TaskModel.fromJson(mutation.payload!));
      }
    }
    return overlaid;
  }

  PendingMutation? mutationFor(String entityId) => mutations.get(entityType, entityId);

  List<PendingMutation> allPendingMutations() => mutations.allFor(entityType);

  Future<void> recordMutation(PendingMutation mutation) => mutations.put(mutation);

  Future<void> discardMutation(String entityId) => mutations.delete(entityType, entityId);

  /// Dispatches one queued mutation to the network. Returns the resulting [TaskModel] for
  /// a successful create/update, `null` for a successful delete.
  Future<TaskModel?> flushMutation(PendingMutation mutation) async {
    switch (mutation.op) {
      case MutationOp.create:
        return remote.createTask(TaskModel.fromJson(mutation.payload!));
      case MutationOp.update:
        final task = TaskModel.fromJson(mutation.payload!);
        return remote.updateTask(
          id: mutation.entityId,
          title: task.title,
          description: task.description,
          priority: task.priority,
          status: task.status,
          dueDate: task.dueDate,
        );
      case MutationOp.delete:
        await remote.deleteTask(id: mutation.entityId);
        return null;
    }
  }
}
