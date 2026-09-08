import 'dart:async';

import 'package:huddle/core/data/pending_mutation.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/services/api_result.dart';
import 'package:huddle/core/services/task_service.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';
import 'package:huddle/features/task/data/task_repository.dart';
import 'package:huddle/features/task/models/task_model.dart';
import 'package:uuid/uuid.dart';

/// Per-task sync status for the offline write queue - drives the pending/failed badge on
/// `TaskTile`. `synced` covers both "never had a pending write" and "successfully flushed".
enum TaskSyncState { synced, pending, failed }

class TaskProvider extends BaseProvider {
  TaskProvider({
    required this.taskService,
    required this.taskRepository,
    required this.groupProvider,
    required this.profileProvider,
  });
  final TaskService taskService;
  final TaskRepository taskRepository;
  final GroupProvider groupProvider;
  final ProfileProvider profileProvider;

  static const _entityType = 'task';
  static const _tempIdPrefix = 'local-';
  static const _maxAttempts = 5;

  // In-memory only - a restart clears it, which is fine since the underlying
  // PendingMutation stays `pending` in storage and just gets retried fresh.
  final Set<String> _inFlightIds = {};
  // temp id -> real id, populated once a queued create's flush succeeds. Lets a screen
  // that's still holding a temp id (e.g. TaskDetailScreen opened right after an offline
  // create) resolve to the real one once it exists.
  final Map<String, String> _idRemap = {};

  /// Loading is driven explicitly by GlobalDataProvider.loadAllData, so there's nothing to
  /// self-trigger here - it just needs to satisfy the BaseProvider contract.
  @override
  void onInit() {}

  @override
  void onDispose() {
    clearTasks();
  }

  List<TaskModel> _tasks = [];

  /// The task list filtered by [priorityFilter]/[selectedDate] and sorted by [sortOption].
  /// Status filtering happens server-side (see [loadTasks]), so [_tasks] already reflects it.
  List<TaskModel> get tasks => _applySort(_tasks.where(_matchesClientFilters).toList());

  /// Looks up a task by id in the raw, unfiltered list - unlike [tasks], this ignores the
  /// current priority/date filters, so a screen holding a reference to one specific task
  /// (e.g. TaskDetailScreen) can still find it even if it wouldn't appear in the filtered
  /// list right now.
  TaskModel? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Resolves a temp id to its real server id once the create that made it has synced;
  /// returns [id] unchanged otherwise (already-real ids, or a create still pending).
  String currentIdFor(String id) => _idRemap[id] ?? id;

  TaskSyncState syncStateFor(String id) {
    final mutation = taskRepository.mutationFor(id);
    if (mutation == null) return TaskSyncState.synced;
    return mutation.state == MutationSyncState.failed ? TaskSyncState.failed : TaskSyncState.pending;
  }

  /// Calendar days (at midnight) that have at least one open task due - used by
  /// [TaskDateCarousel] to show a pending-task dot. Ignores [priorityFilter] and
  /// [selectedDate] since it's a whole-week overview, not the current list view;
  /// like [tasks], it's still limited to whatever [taskStatusFilter] loaded server-side.
  Set<DateTime> get datesWithPendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.open && t.dueDate != null).map((t) => t.dueDate!.atMidnight).toSet();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // `null` represents "both" - all statuses - and is the default so the list
  // opens showing open and closed tasks together.
  TaskStatus? _taskStatusFilter;
  TaskStatus? get taskStatusFilter => _taskStatusFilter;

  // `null` represents "all" priorities.
  TaskPriority? _priorityFilter;
  TaskPriority? get priorityFilter => _priorityFilter;

  TaskSortOption _sortOption = TaskSortOption.dueDate;
  TaskSortOption get sortOption => _sortOption;

  /// Day shown in [TaskDateCarousel] and used to scope [tasks] - defaults to today.
  DateTime _selectedDate = DateTime.now().atMidnight;
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date.atMidnight;
    notifyListeners();
  }

  /// Lower bound for [TaskCalendarDrawer] - falls back to today when the profile
  /// hasn't loaded `createdAt` yet, so the calendar just opens to a single month
  /// rather than letting the user page back indefinitely.
  DateTime get accountCreatedDate => (profileProvider.profile?.createdAt ?? DateTime.now()).atMidnight;

  void setTaskStatusFilter(TaskStatus? status) {
    _taskStatusFilter = status;
    loadTasks();
  }

  /// Commits a full set of filter/sort selections at once - used by [TaskFilterSheet]'s
  /// Apply button so picking individual pills/dropdowns doesn't filter the list until then.
  /// The sheet commits the group scope to [groupProvider] (see [GroupProvider.setGroupScope])
  /// before calling this. [groupScopeChanged] is passed in rather than derived here because
  /// "did the scope change" also depends on which specific group is now active, which this
  /// provider doesn't track - only the caller, which holds both [GroupProvider] and this
  /// provider, can tell.
  void applyFilters({
    required TaskStatus? status,
    required TaskPriority? priority,
    required TaskSortOption sortOption,
    required bool groupScopeChanged,
  }) {
    _priorityFilter = priority;
    _sortOption = sortOption;
    final statusChanged = status != _taskStatusFilter;
    _taskStatusFilter = status;
    if (statusChanged || groupScopeChanged) {
      loadTasks();
    } else {
      notifyListeners();
    }
  }

  void clearFilters() {
    _priorityFilter = null;
    _sortOption = TaskSortOption.dueDate;
    setTaskStatusFilter(null);
  }

  void setTasks(List<TaskModel> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void addTask(TaskModel task) {
    _tasks = [..._tasks, task];
    notifyListeners();
  }

  void clearTasks() {
    _tasks = [];
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await taskService.listTasks(
        status: _taskStatusFilter,
        groupId: groupProvider.showAllGroups ? null : groupProvider.activeGroupId,
      );
      setTasks(taskRepository.applyPendingOverlay(result));
    } on TaskServiceException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Populates from the local cache instantly, with no loading/error state - called once
  /// by GlobalDataProvider.primeFromCache() before Home is ever shown, so the list isn't
  /// empty while [syncTasks] is still in flight against a possibly cold-starting server.
  void primeFromCache() {
    final cached = taskRepository.cachedTasks();
    if (cached.isNotEmpty) setTasks(cached);
  }

  /// Background refresh from the network - called by GlobalDataProvider.syncAllData() on
  /// app open/resume/reconnect. Unlike [loadTasks], a failure here is silent: the
  /// cached/previous list stays on screen rather than surfacing an error, since the user
  /// never asked for this reload.
  Future<void> syncTasks() async {
    try {
      final result = await taskRepository.syncTasks(
        status: _taskStatusFilter,
        groupId: groupProvider.showAllGroups ? null : groupProvider.activeGroupId,
      );
      setTasks(result);
    } on TaskServiceException {
      // Swallowed by design - see doc comment above.
    }
  }

  // ---------------------------------------------------------------------------------
  // Mutations - always apply optimistically and queue for background delivery, online
  // or offline, so nothing ever blocks on the network (see the offline write-queue plan).
  // ---------------------------------------------------------------------------------

  Future<TaskModel> createTask(TaskModel task) async {
    final tempId = '$_tempIdPrefix${const Uuid().v4()}';
    final optimistic = task.copyWith(id: tempId);
    if (_matchesStatusFilter(optimistic.status)) {
      addTask(optimistic);
    }
    await _recordMutation(entityId: tempId, op: MutationOp.create, task: optimistic);
    unawaited(_flushOne(taskRepository.mutationFor(tempId)!));
    return optimistic;
  }

  Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
  }) async {
    final current = taskById(id);
    if (current == null) throw StateError('TaskProvider.updateTask: no task with id $id');
    final updated = current.copyWith(title: title, description: description, priority: priority, status: status, dueDate: dueDate);
    setTasks([
      for (final t in _tasks)
        if (t.id != id) t,
      if (_matchesStatusFilter(updated.status)) updated,
    ]);

    // A still-pending, not-yet-synced create just gets its payload replaced - it's not a
    // separate "update" against a server id yet.
    final existingOp = taskRepository.mutationFor(id)?.op;
    final op = existingOp == MutationOp.create ? MutationOp.create : MutationOp.update;
    await _recordMutation(entityId: id, op: op, task: updated);
    unawaited(_flushOne(taskRepository.mutationFor(id)!));
    return updated;
  }

  Future<void> deleteTask(String id) async {
    setTasks([
      for (final t in _tasks)
        if (t.id != id) t,
    ]);

    final existing = taskRepository.mutationFor(id);
    if (existing != null && existing.op == MutationOp.create && !_inFlightIds.contains(id)) {
      // Never made it to the server and never will - nothing to tell it.
      await taskRepository.discardMutation(id);
      return;
    }
    await _recordMutation(entityId: id, op: MutationOp.delete, task: null);
    unawaited(_flushOne(taskRepository.mutationFor(id)!));
  }

  /// Records/coalesces one local mutation. A mutation for an id currently mid-flight
  /// (see [_inFlightIds]) is stored with `dirty: true` rather than triggering a second,
  /// overlapping network call - see `_finishCreate`/`_finishUpdate` for how a dirty record
  /// gets replayed once the in-flight attempt resolves.
  Future<void> _recordMutation({required String entityId, required MutationOp op, required TaskModel? task}) async {
    await taskRepository.recordMutation(
      PendingMutation(
        entityType: _entityType,
        entityId: entityId,
        op: op,
        payload: task?.toCacheJson(),
        queuedAt: DateTime.now(),
        dirty: _inFlightIds.contains(entityId),
      ),
    );
  }

  /// Dispatches every non-in-flight pending task mutation to the network. Safe to call
  /// repeatedly (app resume/reconnect) - already-in-flight entries are skipped.
  Future<void> flushPending() async {
    final pending = taskRepository.allPendingMutations();
    await Future.wait(pending.map(_flushOne));
  }

  Future<void> _flushOne(PendingMutation mutation) async {
    if (_inFlightIds.contains(mutation.entityId)) return;
    _inFlightIds.add(mutation.entityId);
    try {
      final result = await taskRepository.flushMutation(mutation);
      switch (mutation.op) {
        case MutationOp.create:
          await _finishCreate(mutation.entityId, result!);
        case MutationOp.update:
          await _finishUpdate(mutation.entityId, result!);
        case MutationOp.delete:
          await taskRepository.discardMutation(mutation.entityId);
      }
    } on TaskServiceException catch (e) {
      await _handleFlushFailure(mutation, e);
    } finally {
      _inFlightIds.remove(mutation.entityId);
      notifyListeners();
    }
  }

  Future<void> _finishCreate(String tempId, TaskModel result) async {
    _idRemap[tempId] = result.id!;
    final coalesced = taskRepository.mutationFor(tempId);
    await taskRepository.discardMutation(tempId);

    if (coalesced == null || !coalesced.dirty) {
      setTasks([
        for (final t in _tasks)
          if (t.id == tempId) result else t,
      ]);
      return;
    }

    // A local edit/delete arrived while this create was still in flight - the POST already
    // went out with the pre-edit payload, so it was never sent. Replay it now against the
    // real id: an edit becomes an `update` (the entity now exists), a delete stays a delete.
    final followUp = coalesced.op == MutationOp.delete
        ? PendingMutation(entityType: _entityType, entityId: result.id!, op: MutationOp.delete, payload: null, queuedAt: coalesced.queuedAt)
        : PendingMutation(
            entityType: _entityType,
            entityId: result.id!,
            op: MutationOp.update,
            payload: coalesced.payload,
            queuedAt: coalesced.queuedAt,
          );
    await taskRepository.recordMutation(followUp);

    if (followUp.op == MutationOp.delete) {
      setTasks([
        for (final t in _tasks)
          if (t.id != tempId) t,
      ]);
    } else {
      final patched = TaskModel.fromJson(followUp.payload!).copyWith(id: result.id);
      setTasks([
        for (final t in _tasks)
          if (t.id == tempId) patched else t,
      ]);
    }
    unawaited(_flushOne(followUp));
  }

  Future<void> _finishUpdate(String id, TaskModel result) async {
    final coalesced = taskRepository.mutationFor(id);
    if (coalesced == null || !coalesced.dirty) {
      await taskRepository.discardMutation(id);
      setTasks([
        for (final t in _tasks)
          if (t.id == id) result else t,
      ]);
      return;
    }

    // A local edit/delete arrived while this update was in flight - replay it now.
    final followUp = coalesced.copyWith(dirty: false, attempts: 0);
    await taskRepository.recordMutation(followUp);
    if (followUp.op == MutationOp.delete) {
      setTasks([
        for (final t in _tasks)
          if (t.id != id) t,
      ]);
    } else {
      setTasks([
        for (final t in _tasks)
          if (t.id == id) TaskModel.fromJson(followUp.payload!) else t,
      ]);
    }
    unawaited(_flushOne(followUp));
  }

  Future<void> _handleFlushFailure(PendingMutation mutation, TaskServiceException e) async {
    final current = taskRepository.mutationFor(mutation.entityId) ?? mutation;

    // The item is already gone server-side (someone/something else deleted it first) -
    // that's the intended end state for an update or delete, not a real failure.
    if (mutation.op != MutationOp.create && e.statusCode == 404) {
      await taskRepository.discardMutation(mutation.entityId);
      setTasks([
        for (final t in _tasks)
          if (t.id != mutation.entityId) t,
      ]);
      return;
    }

    final isPermanent = e.type == FailureType.badResponse && (e.statusCode == null || e.statusCode! < 500);
    if (isPermanent || current.attempts + 1 >= _maxAttempts) {
      await taskRepository.recordMutation(current.copyWith(state: MutationSyncState.failed, attempts: current.attempts + 1));
    } else {
      await taskRepository.recordMutation(current.copyWith(attempts: current.attempts + 1));
    }
  }

  /// Resets a permanently-failed mutation and retries it - used by the TaskTile action
  /// sheet's "Retry" option.
  Future<void> retryFailed(String id) async {
    final mutation = taskRepository.mutationFor(id);
    if (mutation == null) return;
    final reset = mutation.copyWith(state: MutationSyncState.pending, attempts: 0, dirty: false);
    await taskRepository.recordMutation(reset);
    unawaited(_flushOne(reset));
  }

  /// Drops a permanently-failed mutation without retrying - used by the TaskTile action
  /// sheet's "Discard" option. Also removes the local item if it was never actually
  /// created server-side.
  Future<void> discardFailed(String id) async {
    final mutation = taskRepository.mutationFor(id);
    await taskRepository.discardMutation(id);
    if (mutation?.op == MutationOp.create) {
      setTasks([
        for (final t in _tasks)
          if (t.id != id) t,
      ]);
    } else {
      notifyListeners();
    }
  }

  bool _matchesStatusFilter(TaskStatus? status) => _taskStatusFilter == null || status == _taskStatusFilter;

  bool _matchesClientFilters(TaskModel task) {
    if (_priorityFilter != null && task.priority != _priorityFilter) return false;
    // Undated tasks have no day to be scoped to, so they show alongside every day's list.
    return task.dueDate == null || _isSameDay(task.dueDate, _selectedDate);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<TaskModel> _applySort(List<TaskModel> tasks) {
    final sorted = [...tasks];
    switch (_sortOption) {
      case TaskSortOption.dueDate:
        sorted.sort(_compareByDueDate);
      case TaskSortOption.priority:
        sorted.sort((a, b) => _priorityRank(b.priority).compareTo(_priorityRank(a.priority)));
    }
    return sorted;
  }

  /// Soonest due date first; tasks without a due date sort to the end.
  int _compareByDueDate(TaskModel a, TaskModel b) {
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  int _priorityRank(TaskPriority? priority) => switch (priority) {
    TaskPriority.high => 3,
    TaskPriority.medium => 2,
    TaskPriority.low => 1,
    null => 0,
  };
}
