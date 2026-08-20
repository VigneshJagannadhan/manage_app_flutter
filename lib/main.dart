import 'package:flutter/material.dart';
import 'package:manage_app/core/providers/app_providers.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/services/session_expired_notifier.dart';
import 'package:manage_app/core/themes/app_theme.dart';
import 'package:manage_app/features/auth/screens/sign_in_screen.dart';
import 'package:manage_app/features/auth/screens/splash_screen.dart';
import 'package:manage_app/features/settings/providers/font_provider.dart';
import 'package:manage_app/features/settings/providers/theme_provider.dart';
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
    return AppProviders(
      child: Consumer2<ThemeProvider, FontProvider>(
        builder: (_, themeProvider, fontProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            theme: AppThemes.lightTheme(font: fontProvider.font),
            darkTheme: AppThemes.darkTheme(font: fontProvider.font),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
