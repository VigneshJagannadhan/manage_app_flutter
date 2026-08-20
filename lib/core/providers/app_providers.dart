import 'package:flutter/material.dart';
import 'package:manage_app/core/providers/global_data_provider.dart';
import 'package:manage_app/core/services/auth_service.dart';
import 'package:manage_app/core/services/expense_service.dart';
import 'package:manage_app/core/services/group_preference_service.dart';
import 'package:manage_app/core/services/group_service.dart';
import 'package:manage_app/core/services/journal_service.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/core/services/font_preference_service.dart';
import 'package:manage_app/core/services/theme_preference_service.dart';
import 'package:manage_app/core/services/token_storage_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/journal/providers/journal_provider.dart';
import 'package:manage_app/features/settings/providers/font_provider.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/settings/providers/theme_provider.dart';
import 'package:manage_app/features/settings/services/profile_service.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:provider/provider.dart';

/// Constructs every app-wide provider and exposes them to [child] via [MultiProvider].
/// Lives in `core` (rather than main.dart) so the provider wiring/dependency graph is
/// separate from the app's root widget and MaterialApp setup.
class AppProviders extends StatefulWidget {
  const AppProviders({required this.child, super.key});

  final Widget child;

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final _authProvider = AuthProvider(authService: authService, tokenStorageService: tokenStorageService)..onInit();
  late final _profileProvider = ProfileProvider(profileService: profileService)..onInit();

  // Depends on _authProvider being constructed first so GroupProvider.onInit() sees its
  // real isAuthenticated value instead of racing session restoration/login, and on
  // _profileProvider for reading/syncing the account's server-side default group.
  late final _groupProvider =
      GroupProvider(
          groupService: groupService,
          groupPreferenceService: groupPreferenceService,
          authProvider: _authProvider,
          profileProvider: _profileProvider,
        )
        ..onInit();

  late final _taskProvider = TaskProvider(taskService: taskService, groupProvider: _groupProvider)..onInit();
  late final _expenseProvider = ExpenseProvider(expenseService: expenseService, groupProvider: _groupProvider)..onInit();
  late final _journalProvider = JournalProvider(journalService: journalService, profileProvider: _profileProvider)..onInit();

  late final _globalDataProvider =
      GlobalDataProvider(
          authProvider: _authProvider,
          groupProvider: _groupProvider,
          taskProvider: _taskProvider,
          expenseProvider: _expenseProvider,
          profileProvider: _profileProvider,
          journalProvider: _journalProvider,
        )
        ..onInit();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _groupProvider),
        ChangeNotifierProvider.value(value: _taskProvider),
        ChangeNotifierProvider.value(value: _expenseProvider),
        ChangeNotifierProvider.value(value: _journalProvider),
        ChangeNotifierProvider.value(value: _profileProvider),
        ChangeNotifierProvider.value(value: _globalDataProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider(themePreferenceService: themePreferenceService)..onInit()),
        ChangeNotifierProvider(create: (_) => FontProvider(fontPreferenceService: fontPreferenceService)..onInit()),
      ],
      child: widget.child,
    );
  }
}
