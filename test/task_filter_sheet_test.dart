import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/enums/task_enums.dart';
import 'package:huddle/core/resources/app_fonts.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/auth_service.dart';
import 'package:huddle/core/services/connectivity_service.dart';
import 'package:huddle/core/services/expense_service.dart';
import 'package:huddle/core/services/group_preference_service.dart';
import 'package:huddle/core/services/group_service.dart';
import 'package:huddle/core/services/journal_service.dart';
import 'package:huddle/core/services/task_service.dart';
import 'package:huddle/core/services/token_storage_service.dart';
import 'package:huddle/core/themes/app_theme.dart';
import 'package:huddle/features/auth/models/auth_session_model.dart';
import 'package:huddle/features/auth/models/token_pair_model.dart';
import 'package:huddle/features/auth/models/user_model.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/expense/models/expense_model.dart';
import 'package:huddle/features/expense/providers/expense_provider.dart';
import 'package:huddle/features/group/models/group_model.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/home/screens/home_screen.dart';
import 'package:huddle/features/journal/data/journal_local_data_source.dart';
import 'package:huddle/features/journal/data/journal_repository.dart';
import 'package:huddle/features/journal/models/journal_entry_model.dart';
import 'package:huddle/features/journal/providers/journal_provider.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/settings/services/profile_service.dart';
import 'package:huddle/features/task/models/task_model.dart';
import 'package:huddle/features/task/providers/task_provider.dart';
import 'package:provider/provider.dart';

class _FakeTokenStorageService extends TokenStorageService {
  @override
  Future<AuthSessionModel?> readSession() async => AuthSessionModel(
    user: const UserModel(id: 'user-1', name: 'Test User', email: 'test@example.com'),
    tokens: const TokenPairModel(accessToken: 'access', refreshToken: 'refresh'),
  );
}

class _FakeGroupService extends GroupService {
  @override
  Future<List<GroupModel>> listGroups() async => [
    GroupModel(id: 'group-1', name: 'Test Group', inviteCode: 'TESTCODE', createdBy: 'user-1', createdAt: DateTime(2026, 1, 1)),
  ];
}

class _FakeProfileService extends ProfileService {
  @override
  Future<UserModel> getProfile() async =>
      const UserModel(id: 'user-1', name: 'Test User', email: 'test@example.com');
}

class _FakeGroupPreferenceService extends GroupPreferenceService {
  @override
  Future<String?> readActiveGroupId() async => null;

  @override
  Future<void> saveActiveGroupId(String? groupId) async {}

  @override
  Future<bool> readTasksShowAllGroups() async => true;

  @override
  Future<void> saveTasksShowAllGroups(bool value) async {}

  @override
  Future<void> clearTasksShowAllGroups() async {}

  @override
  Future<bool> readExpensesShowAllGroups() async => true;

  @override
  Future<void> saveExpensesShowAllGroups(bool value) async {}

  @override
  Future<void> clearExpensesShowAllGroups() async {}
}

class _FakeExpenseService extends ExpenseService {
  @override
  Future<List<ExpenseModel>> listExpenses({ExpenseCategory? category, String? groupId}) async => [];
}

class _FakeJournalService extends JournalService {
  @override
  Future<List<JournalEntryModel>> listEntries({required DateTime from, required DateTime to}) async => [];
}

class _FakeJournalLocalDataSource extends JournalLocalDataSource {
  @override
  Future<void> saveDraft(DateTime date, String content) async {}

  @override
  JournalDraft? getDraft(DateTime date) => null;

  @override
  Future<void> markSynced(DateTime date) async {}

  @override
  List<DateTime> dirtyDates() => const [];

  @override
  Future<void> clearAll() async {}
}

class _FakeConnectivityService extends ConnectivityService {
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  Future<bool> get isConnected async => true;
}

class _FakeTaskService extends TaskService {
  @override
  Future<List<TaskModel>> listTasks({TaskStatus? status, String? groupId}) async {
    final all = [
      TaskModel(
        id: '1',
        title: 'High priority, due today',
        description: '',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        createdAt: DateTime(2026, 1, 1),
        dueDate: DateTime.now(),
      ),
      TaskModel(
        id: '2',
        title: 'Low priority, due tomorrow',
        description: '',
        priority: TaskPriority.low,
        status: TaskStatus.open,
        createdAt: DateTime(2026, 1, 2),
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
      TaskModel(
        id: '3',
        title: 'Completed task',
        description: '',
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        createdAt: DateTime(2026, 1, 3),
        dueDate: null,
      ),
    ];
    if (status == null) return all;
    return all.where((t) => t.status == status).toList();
  }
}

Future<void> _pumpHome(WidgetTester tester) async {
  final authProvider = AuthProvider(authService: AuthService(), tokenStorageService: _FakeTokenStorageService())..onInit();
  await authProvider.restoreSession();
  final profileProvider = ProfileProvider(profileService: _FakeProfileService())..onInit();
  final groupPreferenceService = _FakeGroupPreferenceService();
  final groupProvider =
      GroupProvider(
          groupService: _FakeGroupService(),
          groupPreferenceService: groupPreferenceService,
          authProvider: authProvider,
          profileProvider: profileProvider,
        )
        ..onInit();
  final taskProvider =
      TaskProvider(taskService: _FakeTaskService(), groupProvider: groupProvider, groupPreferenceService: groupPreferenceService)..onInit();
  final expenseProvider =
      ExpenseProvider(expenseService: _FakeExpenseService(), groupProvider: groupProvider, groupPreferenceService: groupPreferenceService)
        ..onInit();
  final journalService = _FakeJournalService();
  final journalProvider =
      JournalProvider(
          journalService: journalService,
          repository: JournalRepository(local: _FakeJournalLocalDataSource(), remote: journalService),
          connectivityService: _FakeConnectivityService(),
          profileProvider: profileProvider,
        )
        ..onInit();

  // Providers no longer self-load on init - AppProvider.loadAllData drives that from
  // splash. Mirror that sequence here so the fake data actually reaches the widgets.
  await profileProvider.loadProfile();
  await groupProvider.restoreActiveGroup();
  await Future.wait([taskProvider.restoreShowAllGroups(), expenseProvider.restoreShowAllGroups()]);
  await Future.wait([taskProvider.loadTasks(), expenseProvider.loadExpenses(), journalProvider.loadInitial()]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: groupProvider),
        ChangeNotifierProvider.value(value: taskProvider),
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: journalProvider),
      ],
      child: MaterialApp(theme: AppThemes.lightTheme(font: AppFontOption.defaultOption), home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('filter icon opens the filter & sort sheet', (tester) async {
    await _pumpHome(tester);

    expect(find.text('High priority, due today'), findsOneWidget);
    expect(find.text('Low priority, due tomorrow'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing); // default status filter is Open

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.filterAndSort), findsOneWidget);
    expect(find.text(AppStrings.statusLabel), findsOneWidget);
    expect(find.text(AppStrings.priorityLabel), findsOneWidget);
    expect(find.text(AppStrings.sortByLabel), findsOneWidget);
    expect(find.text(AppStrings.dateLabel), findsOneWidget);
  });

  testWidgets('selecting "All" status only applies once Apply is pressed', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    // Status dropdown currently shows "Open" (the default filter); tap it to open the
    // panel, then pick "All" from the list of options.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final allOption = find.text(AppStrings.all).first;
    await tester.ensureVisible(allOption);
    await tester.pumpAndSettle();
    await tester.tap(allOption);
    await tester.pumpAndSettle();

    // Picking the pill must not touch the provider yet - only Apply commits it.
    final provider = tester.element(find.byType(HomeScreen)).read<TaskProvider>();
    expect(provider.taskStatusFilter, TaskStatus.open, reason: 'selecting a filter should stage it, not apply it immediately');

    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(provider.taskStatusFilter, isNull, reason: 'status filter should be null (both) after pressing Apply');
    expect(find.text('Completed task'), findsOneWidget);
  });

  testWidgets('date filter chip only filters the list once Apply is pressed', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tomorrow));
    await tester.pumpAndSettle();

    // Closing without Apply must discard the staged pill selection.
    await tester.tap(find.byTooltip(AppStrings.closeTooltip));
    await tester.pumpAndSettle();

    expect(find.text('High priority, due today'), findsOneWidget);
    expect(find.text('Low priority, due tomorrow'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tomorrow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(find.text('High priority, due today'), findsNothing);
    expect(find.text('Low priority, due tomorrow'), findsOneWidget);
  });

  testWidgets('Clear All stages defaults, applied only once Apply is pressed', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tomorrow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.clearAll));
    await tester.pumpAndSettle();

    final provider = tester.element(find.byType(HomeScreen)).read<TaskProvider>();
    expect(provider.dateFilterOption, TaskDateFilterOption.all, reason: 'Clear All should not touch the provider until Apply is pressed');

    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(provider.dateFilterOption, TaskDateFilterOption.all);
    expect(provider.priorityFilter, isNull);
    expect(provider.sortOption, TaskSortOption.dueDate);
    expect(provider.taskStatusFilter, TaskStatus.open);
  });
}
