import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';
import 'package:manage_app/features/task/models/task_model.dart';

class TaskProvider extends BaseProvider {
  TaskProvider({required this.taskService, required this.groupProvider});
  final TaskService taskService;
  final GroupProvider groupProvider;

  @override
  void onInit() {
    _init();
  }

  /// Waits for [GroupProvider] to finish restoring the active group before the first
  /// load, so this doesn't fetch in "all groups" mode just because that's still in flight.
  Future<void> _init() async {
    await groupProvider.ready;
    await loadTasks();
  }

  @override
  void onDispose() {
    clearTasks();
  }

  List<TaskModel> _tasks = [];

  /// The task list filtered by [priorityFilter]/[dateFilterOption] and sorted by [sortOption].
  /// Status filtering happens server-side (see [loadTasks]), so [_tasks] already reflects it.
  List<TaskModel> get tasks => _applySort(_tasks.where(_matchesClientFilters).toList());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // `null` represents "both" - all statuses.
  TaskStatus? _taskStatusFilter = TaskStatus.open;
  TaskStatus? get taskStatusFilter => _taskStatusFilter;

  // `null` represents "all" priorities.
  TaskPriority? _priorityFilter;
  TaskPriority? get priorityFilter => _priorityFilter;

  TaskSortOption _sortOption = TaskSortOption.dueDate;
  TaskSortOption get sortOption => _sortOption;

  TaskDateFilterOption _dateFilterOption = TaskDateFilterOption.all;
  TaskDateFilterOption get dateFilterOption => _dateFilterOption;

  DateTime? _customDate;
  DateTime? get customDate => _customDate;

  bool _showAllGroups = false;
  bool get showAllGroups => _showAllGroups;

  void toggleShowAllGroups(bool value) {
    _showAllGroups = value;
    loadTasks();
  }

  void setTaskStatusFilter(TaskStatus? status) {
    _taskStatusFilter = status;
    loadTasks();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void setSortOption(TaskSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  /// [customDate] is only kept when [option] is [TaskDateFilterOption.custom].
  void setDateFilter(TaskDateFilterOption option, {DateTime? customDate}) {
    _dateFilterOption = option;
    _customDate = option == TaskDateFilterOption.custom ? customDate : null;
    notifyListeners();
  }

  void clearFilters() {
    _priorityFilter = null;
    _sortOption = TaskSortOption.dueDate;
    _dateFilterOption = TaskDateFilterOption.all;
    _customDate = null;
    setTaskStatusFilter(TaskStatus.open);
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
    return _matchesDateFilter(task);
  }

  bool _matchesDateFilter(TaskModel task) {
    switch (_dateFilterOption) {
      case TaskDateFilterOption.all:
        return true;
      case TaskDateFilterOption.today:
        return _isSameDay(task.dueDate, DateTime.now());
      case TaskDateFilterOption.tomorrow:
        return _isSameDay(task.dueDate, DateTime.now().add(const Duration(days: 1)));
      case TaskDateFilterOption.custom:
        return _customDate != null && _isSameDay(task.dueDate, _customDate);
    }
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
