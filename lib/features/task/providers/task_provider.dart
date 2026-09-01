import 'dart:async';

import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/services/group_preference_service.dart';
import 'package:huddle/core/services/task_service.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';
import 'package:huddle/features/task/models/task_model.dart';

class TaskProvider extends BaseProvider {
  TaskProvider({required this.taskService, required this.groupProvider, required this.groupPreferenceService});
  final TaskService taskService;
  final GroupProvider groupProvider;
  final GroupPreferenceService groupPreferenceService;

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

  bool _showAllGroups = true;
  bool get showAllGroups => _showAllGroups;

  /// Reads the last-picked group scope from local storage. Must complete before
  /// [loadTasks] so the very first load after sign-in respects it - see
  /// GlobalDataProvider.loadAllData.
  Future<void> restoreShowAllGroups() async {
    _showAllGroups = await groupPreferenceService.readTasksShowAllGroups();
    notifyListeners();
  }

  void toggleShowAllGroups(bool value) {
    _showAllGroups = value;
    unawaited(groupPreferenceService.saveTasksShowAllGroups(value));
    loadTasks();
  }

  /// Resets the group-scope choice back to "all groups" and wipes the persisted
  /// preference, so it doesn't linger into the next account signed in on this device.
  void resetShowAllGroupsPreference() {
    _showAllGroups = true;
    unawaited(groupPreferenceService.clearTasksShowAllGroups());
  }

  void setTaskStatusFilter(TaskStatus? status) {
    _taskStatusFilter = status;
    loadTasks();
  }

  /// Commits a full set of filter/sort selections at once - used by [TaskFilterSheet]'s
  /// Apply button so picking individual pills/dropdowns doesn't filter the list until then.
  void applyFilters({required TaskStatus? status, required TaskPriority? priority, required TaskSortOption sortOption}) {
    _priorityFilter = priority;
    _sortOption = sortOption;
    if (status != _taskStatusFilter) {
      setTaskStatusFilter(status);
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
        groupId: _showAllGroups ? null : groupProvider.activeGroupId,
      );
      setTasks(result);
    } on TaskServiceException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel?> createTask(TaskModel task) async {
    final result = await taskService.createTask(task);
    if (result != null && _matchesStatusFilter(result.status)) {
      addTask(result);
    }
    return result;
  }

  Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
  }) async {
    final updated = await taskService.updateTask(
      id: id,
      title: title,
      description: description,
      priority: priority,
      status: status,
      dueDate: dueDate,
    );
    setTasks([
      for (final t in _tasks)
        if (t.id != id) t,
      if (_matchesStatusFilter(updated.status)) updated,
    ]);
    return updated;
  }

  Future<void> deleteTask(String id) async {
    await taskService.deleteTask(id: id);
    setTasks([
      for (final t in _tasks)
        if (t.id != id) t,
    ]);
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
