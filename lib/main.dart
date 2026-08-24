import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:huddle/core/providers/app_providers.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/core/services/session_expired_notifier.dart';
import 'package:huddle/core/themes/app_theme.dart';
import 'package:huddle/features/auth/screens/sign_in_screen.dart';
import 'package:huddle/features/auth/screens/splash_screen.dart';
import 'package:huddle/features/journal/data/journal_local_data_source.dart';
import 'package:huddle/features/settings/providers/font_provider.dart';
import 'package:huddle/features/settings/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await journalLocalDataSource.init();
  } catch (_) {
    // Corrupted/unreadable box - drop it and continue with an empty local cache rather
    // than blocking app launch.
    await Hive.deleteBoxFromDisk(journalLocalDataSource.boxName);
    await journalLocalDataSource.init();
  }
  runApp(const HuddleApp());
}

class HuddleApp extends StatefulWidget {
  const HuddleApp({super.key});

  @override
  State<HuddleApp> createState() => _HuddleAppState();
}

class _HuddleAppState extends State<HuddleApp> {
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
