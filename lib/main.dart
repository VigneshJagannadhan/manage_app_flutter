import 'package:flutter/material.dart';
import 'package:manage_app/core/providers/app_provider.dart';
import 'package:manage_app/core/services/auth_service.dart';
import 'package:manage_app/core/services/expense_service.dart';
import 'package:manage_app/core/services/group_preference_service.dart';
import 'package:manage_app/core/services/group_service.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/services/session_expired_notifier.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/core/services/theme_preference_service.dart';
import 'package:manage_app/core/services/token_storage_service.dart';
import 'package:manage_app/core/themes/app_theme.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/screens/sign_in_screen.dart';
import 'package:manage_app/features/auth/screens/splash_screen.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/settings/providers/theme_provider.dart';
import 'package:manage_app/features/settings/services/profile_service.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const ManageApp());
}

class ManageApp extends StatefulWidget {
  const ManageApp({super.key});

  @override
  State<ManageApp> createState() => _ManageAppState();
}

class _ManageAppState extends State<ManageApp> {
  late final _authProvider = AuthProvider(authService: authService, tokenStorageService: tokenStorageService)..onInit();

  // Depends on _authProvider being constructed first so GroupProvider.onInit() sees
  // its real isAuthenticated value instead of racing session restoration/login.
  late final _groupProvider =
      GroupProvider(groupService: groupService, groupPreferenceService: groupPreferenceService, authProvider: _authProvider)
        ..onInit();

  late final _taskProvider = TaskProvider(taskService: taskService, groupProvider: _groupProvider)..onInit();
  late final _expenseProvider = ExpenseProvider(expenseService: expenseService, groupProvider: _groupProvider)..onInit();
  late final _profileProvider = ProfileProvider(profileService: profileService)..onInit();

  late final _appProvider =
      AppProvider(
          authProvider: _authProvider,
          groupProvider: _groupProvider,
          taskProvider: _taskProvider,
          expenseProvider: _expenseProvider,
          profileProvider: _profileProvider,
        )
        ..onInit();

  @override
  void initState() {
    super.initState();
    sessionExpiredNotifier.addListener(_handleSessionExpired);
  }

  @override
  void dispose() {
    sessionExpiredNotifier.removeListener(_handleSessionExpired);
    super.dispose();
  }

  void _handleSessionExpired() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _groupProvider),
        ChangeNotifierProvider.value(value: _taskProvider),
        ChangeNotifierProvider.value(value: _expenseProvider),
        ChangeNotifierProvider.value(value: _profileProvider),
        ChangeNotifierProvider.value(value: _appProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider(themePreferenceService: themePreferenceService)..onInit()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
