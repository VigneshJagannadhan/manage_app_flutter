import 'package:flutter/material.dart';
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
  late final _groupProvider = GroupProvider(groupService: groupService, groupPreferenceService: groupPreferenceService)
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
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService, tokenStorageService: tokenStorageService)..onInit(),
        ),
        ChangeNotifierProvider.value(value: _groupProvider),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(taskService: taskService, groupProvider: _groupProvider)..onInit(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(expenseService: expenseService, groupProvider: _groupProvider)..onInit(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider(themePreferenceService: themePreferenceService)..onInit()),
        ChangeNotifierProvider(create: (_) => ProfileProvider(profileService: profileService)..onInit()),
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
