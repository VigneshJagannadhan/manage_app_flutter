import 'package:huddle/core/models/scheduled_notification_model.dart';
import 'package:huddle/core/services/expense_service.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/core/services/task_service.dart';
import 'package:huddle/features/expense/screens/expense_detail_screen.dart';
import 'package:huddle/features/home/screens/home_screen.dart';
import 'package:huddle/features/journal/screens/journal_entry_screen.dart';
import 'package:huddle/features/task/screens/task_detail_screen.dart';

/// Routes a tapped reminder notification's `data` payload (see the `data` field shape in
/// `docs/NOTIFICATIONS_BACKEND_REQUIREMENTS.md`) to the right screen. Used from every tap
/// entry point - foreground/background tap while the process is alive, and cold-start via
/// [LocalNotificationService.consumeLaunchPayload] - so all three states route identically.
class NotificationDeepLinkRouter {
  Future<void> handleTapPayload(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = (data['type'] as String?)?.toScheduledNotificationType() ?? ScheduledNotificationType.general;
    switch (type) {
      case ScheduledNotificationType.journal:
        final dateString = data['date'] as String?;
        final date = dateString != null ? DateTime.parse(dateString) : DateTime.now();
        await navigationService.push(context, JournalEntryScreen(date: date));
      case ScheduledNotificationType.task:
        await _openTask(data);
      case ScheduledNotificationType.expense:
        await _openExpense(data);
      case ScheduledNotificationType.general:
        await navigationService.push(context, HomeScreen());
    }
  }

  Future<void> _openTask(Map<String, dynamic> data) async {
    final taskId = data['taskId'] as String?;
    final groupId = data['groupId'] as String?;
    if (taskId == null) return;

    final tasks = await taskService.listTasks(groupId: groupId);
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final task = tasks.where((task) => task.id == taskId).firstOrNull;
    await navigationService.push(context, task != null ? TaskDetailScreen(task: task) : HomeScreen());
  }

  Future<void> _openExpense(Map<String, dynamic> data) async {
    final expenseId = data['expenseId'] as String?;
    final groupId = data['groupId'] as String?;
    if (expenseId == null) return;

    final expenses = await expenseService.listExpenses(groupId: groupId);
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final expense = expenses.where((expense) => expense.id == expenseId).firstOrNull;
    await navigationService.push(context, expense != null ? ExpenseDetailScreen(expense: expense) : HomeScreen());
  }
}

final notificationDeepLinkRouter = NotificationDeepLinkRouter();
