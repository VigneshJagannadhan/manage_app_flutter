import 'package:manage_app/core/services/session_expired_notifier.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';

/// Orchestrates the app-wide load/reset lifecycle across the feature providers. Lives in
/// `core` (rather than alongside a single feature) because it owns no data of its own -
/// it only coordinates providers that do.
class AppProvider extends BaseProvider {
  AppProvider({
    required this.authProvider,
    required this.groupProvider,
    required this.taskProvider,
    required this.expenseProvider,
    required this.profileProvider,
  });

  final AuthProvider authProvider;
  final GroupProvider groupProvider;
  final TaskProvider taskProvider;
  final ExpenseProvider expenseProvider;
  final ProfileProvider profileProvider;

  @override
  void onInit() {
    sessionExpiredNotifier.addListener(resetAllData);
  }

  @override
  void onDispose() {
    sessionExpiredNotifier.removeListener(resetAllData);
  }

  bool _isDataLoaded = false;
  bool get isDataLoaded => _isDataLoaded;

  /// Call once at splash (after [AuthProvider.restoreSession]) and again after every
  /// fresh sign-in/sign-up, so group/task/expense/profile data is populated before the
  /// user reaches Home.
  Future<void> loadAllData() async {
    _isDataLoaded = false;
    if (authProvider.isAuthenticated) {
      await groupProvider.restoreActiveGroup();
      await Future.wait([taskProvider.loadTasks(), expenseProvider.loadExpenses(), profileProvider.loadProfile()]);
    }
    _isDataLoaded = true;
    notifyListeners();
  }

  /// Call on sign-out (manual, from settings, or auth-failure via [sessionExpiredNotifier])
  /// so no account-scoped data lingers into the next session.
  void resetAllData() {
    taskProvider.clearTasks();
    expenseProvider.clearExpenses();
    profileProvider.clearProfile();
    // GroupProvider clears itself reactively via its own AuthProvider listener.
    _isDataLoaded = false;
    notifyListeners();
  }
}
