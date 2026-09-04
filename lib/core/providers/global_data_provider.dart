import 'dart:async';

import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/services/connectivity_service.dart';
import 'package:huddle/core/services/session_expired_notifier.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/expense/providers/expense_provider.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/journal/providers/journal_provider.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';
import 'package:huddle/features/task/providers/task_provider.dart';

/// Orchestrates the app-wide load/reset lifecycle across the feature providers. Lives in
/// `core` (rather than alongside a single feature) because it owns no data of its own -
/// it only coordinates providers that do.
class GlobalDataProvider extends BaseProvider {
  GlobalDataProvider({
    required this.authProvider,
    required this.groupProvider,
    required this.taskProvider,
    required this.expenseProvider,
    required this.profileProvider,
    required this.journalProvider,
    required this.connectivityService,
  });

  final AuthProvider authProvider;
  final GroupProvider groupProvider;
  final TaskProvider taskProvider;
  final ExpenseProvider expenseProvider;
  final ProfileProvider profileProvider;
  final JournalProvider journalProvider;
  final ConnectivityService connectivityService;

  StreamSubscription<bool>? _connectivitySub;

  @override
  void onInit() {
    sessionExpiredNotifier.addListener(resetAllData);
    _connectivitySub = connectivityService.onConnectivityChanged.listen((connected) {
      if (connected) syncIfStale();
    });
  }

  @override
  void onDispose() {
    sessionExpiredNotifier.removeListener(resetAllData);
    _connectivitySub?.cancel();
  }

  bool _isDataLoaded = false;
  bool get isDataLoaded => _isDataLoaded;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncAt;

  static const _minSyncInterval = Duration(seconds: 30);

  /// Fast, local-only - reads whatever's already cached for Profile/Group/Task/Expense so
  /// Home has something to show immediately. Awaited by splash before navigating; never
  /// touches the network, so it can't be held up by a slow/cold-starting server. Journal
  /// isn't primed here - it lazy-loads its own entries when its tab opens and already has
  /// its own offline draft-sync mechanism (see JournalRepository).
  Future<void> primeFromCache() async {
    if (authProvider.isAuthenticated) {
      profileProvider.primeFromCache();
      await groupProvider.primeFromCache();
      taskProvider.primeFromCache();
      expenseProvider.primeFromCache();
    }
    _isDataLoaded = true;
    notifyListeners();
  }

  /// The full network refresh - the same calls this class used to make navigation wait on
  /// before splash was decoupled from the network. Now fire-and-forget from splash, app
  /// resume, and reconnect, so a slow/cold-starting server never blocks the UI; failures
  /// are swallowed inside each provider's `sync*` method, leaving cached data on screen.
  Future<void> syncAllData() async {
    if (!authProvider.isAuthenticated) return;
    _isSyncing = true;
    notifyListeners();
    try {
      // Profile must sync first - GroupProvider's active-group resolution falls back to
      // the profile's server-synced defaultGroupId when there's no local pick yet.
      await profileProvider.syncProfile();
      await groupProvider.syncGroups();
      await Future.wait([
        taskProvider.syncTasks(),
        expenseProvider.syncExpenses(),
        journalProvider.loadInitial(),
      ]);
    } finally {
      _lastSyncAt = DateTime.now();
      _isDataLoaded = true;
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Same as [syncAllData], but skipped if the last sync completed within
  /// [_minSyncInterval] - guards the app-resume/reconnect triggers against hammering the
  /// server on rapid foreground/background switching.
  Future<void> syncIfStale() {
    final lastSyncAt = _lastSyncAt;
    if (lastSyncAt != null && DateTime.now().difference(lastSyncAt) < _minSyncInterval) {
      return Future.value();
    }
    return syncAllData();
  }

  /// Call on sign-out (manual, from settings, or auth-failure via [sessionExpiredNotifier])
  /// so no account-scoped data lingers into the next session.
  void resetAllData() {
    taskProvider.clearTasks();
    expenseProvider.clearExpenses();
    journalProvider.clearEntries();
    profileProvider.clearProfile();
    groupProvider.resetShowAllGroupsPreference();
    unawaited(appDataCache.clearAll());
    // GroupProvider's groups/activeGroupId clear themselves reactively via its own
    // AuthProvider listener.
    _isDataLoaded = false;
    _lastSyncAt = null;
    notifyListeners();
  }
}
