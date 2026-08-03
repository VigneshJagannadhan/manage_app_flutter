enum TaskPriority { low, medium, high }

extension TaskPriorityApi on TaskPriority {
  /// Matches the backend's case-sensitive priority string exactly.
  String get apiValue => switch (this) {
    TaskPriority.low => 'LOW',
    TaskPriority.medium => 'MEDIUM',
    TaskPriority.high => 'HIGH',
  };

  static TaskPriority fromApiValue(String value) => switch (value) {
    'LOW' => TaskPriority.low,
    'MEDIUM' => TaskPriority.medium,
    'HIGH' => TaskPriority.high,
    _ => throw ArgumentError('Unknown task priority: $value'),
  };
}

enum TaskStatus { open, completed }

extension TaskStatusApi on TaskStatus {
  /// Matches the backend's case-sensitive status string exactly.
  String get apiValue => switch (this) {
    TaskStatus.open => 'OPEN',
    TaskStatus.completed => 'COMPLETED',
  };

  static TaskStatus fromApiValue(String value) => switch (value) {
    'OPEN' => TaskStatus.open,
    'COMPLETED' => TaskStatus.completed,
    _ => throw ArgumentError('Unknown task status: $value'),
  };
}

/// Client-side sort applied to the task list. Not sent to the API.
enum TaskSortOption { dueDate, priority }

/// Client-side due-date filter applied to the task list. Not sent to the API.
enum TaskDateFilterOption { all, today, tomorrow, custom }
