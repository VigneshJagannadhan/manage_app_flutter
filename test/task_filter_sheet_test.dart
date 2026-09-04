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
import 'package:huddle/features/shared/widgets/app_dropdown_field.dart';
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
  Future<bool> readShowAllGroups() async => true;

  @override
  Future<void> saveShowAllGroups(bool value) async {}

  @override
  Future<void> clearShowAllGroups() async {}
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

/// Monday of the calendar week containing [date] - mirrors the week window
/// [TaskDateCarousel] computes internally.
DateTime _startOfWeek(DateTime date) {
  final atMidnight = DateTime(date.year, date.month, date.day);
  return atMidnight.subtract(Duration(days: atMidnight.weekday - DateTime.monday));
}

/// A day guaranteed to fall in the same week as today but not be today itself -
/// used so tests don't depend on which real-world weekday they happen to run on.
DateTime _otherDayInCurrentWeek() {
  final today = DateTime.now();
  final weekStart = _startOfWeek(today);
  final todayMidnight = DateTime(today.year, today.month, today.day);
  return todayMidnight.isAtSameMomentAs(weekStart) ? weekStart.add(const Duration(days: 1)) : weekStart;
}

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The accessibility label [TaskDateCarousel] gives the day cell for [date].
String _dayCellLabel(DateTime date, {bool hasPendingTask = false}) {
  final base = '${_weekdayLetters[date.weekday - 1]} ${date.day}';
  return hasPendingTask ? '$base, has pending tasks' : base;
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
        title: 'Low priority, due another day',
        description: '',
        priority: TaskPriority.low,
        status: TaskStatus.open,
        createdAt: DateTime(2026, 1, 2),
        dueDate: _otherDayInCurrentWeek(),
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
      TaskProvider(
          taskService: _FakeTaskService(),
          groupProvider: groupProvider,
          profileProvider: profileProvider,
        )
        ..onInit();
  final expenseProvider =
      ExpenseProvider(
          expenseService: _FakeExpenseService(),
          groupProvider: groupProvider,
          profileProvider: profileProvider,
        )
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

    // Default selected day is today, so the other task's day is out of scope;
    // the completed task has no due date so it shows regardless of selected day.
    // Default status filter is "both", so open and closed tasks show together.
    expect(find.text('High priority, due today'), findsOneWidget);
    expect(find.text('Low priority, due another day'), findsNothing);
    expect(find.text('Completed task'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.filterAndSort), findsOneWidget);
    expect(find.text(AppStrings.statusLabel), findsOneWidget);
    expect(find.text(AppStrings.priorityLabel), findsOneWidget);
    expect(find.text(AppStrings.sortByLabel), findsOneWidget);
  });

  testWidgets('selecting "Open" status only applies once Apply is pressed', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    // Status dropdown shows no text when its value is "All" (null); open it by
    // type, then pick "Open" from the list of options.
    await tester.tap(find.byType(AppDropdownField<TaskStatus?>));
    await tester.pumpAndSettle();
    final openOption = find.text('Open').last;
    await tester.ensureVisible(openOption);
    await tester.pumpAndSettle();
    await tester.tap(openOption);
    await tester.pumpAndSettle();

    // Picking the pill must not touch the provider yet - only Apply commits it.
    final provider = tester.element(find.byType(HomeScreen)).read<TaskProvider>();
    expect(provider.taskStatusFilter, isNull, reason: 'selecting a filter should stage it, not apply it immediately');

    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(provider.taskStatusFilter, TaskStatus.open, reason: 'status filter should be Open after pressing Apply');
    expect(find.text('Completed task'), findsNothing);
  });

  testWidgets('tapping a day in the calendar carousel scopes the list to that day', (tester) async {
    await _pumpHome(tester);

    expect(find.text('High priority, due today'), findsOneWidget);
    expect(find.text('Low priority, due another day'), findsNothing);

    await tester.tap(find.bySemanticsLabel(_dayCellLabel(_otherDayInCurrentWeek(), hasPendingTask: true)));
    await tester.pumpAndSettle();

    expect(find.text('High priority, due today'), findsNothing);
    expect(find.text('Low priority, due another day'), findsOneWidget);
  });

  testWidgets('Clear All stages defaults, applied only once Apply is pressed', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    // Priority dropdown shows no text when its value is "All" (null); open it by type and stage "High".
    await tester.tap(find.byType(AppDropdownField<TaskPriority?>));
    await tester.pumpAndSettle();
    final highOption = find.text('High').last;
    await tester.ensureVisible(highOption);
    await tester.pumpAndSettle();
    await tester.tap(highOption);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.clearAll));
    await tester.pumpAndSettle();

    expect(find.text('High'), findsNothing, reason: 'Clear All should reset the staged priority back to All');

    final provider = tester.element(find.byType(HomeScreen)).read<TaskProvider>();
    expect(provider.priorityFilter, isNull, reason: 'Clear All should not touch the provider until Apply is pressed');

    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(provider.priorityFilter, isNull);
    expect(provider.sortOption, TaskSortOption.dueDate);
    expect(provider.taskStatusFilter, isNull);
  });
}
