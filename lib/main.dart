import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/providers/app_providers.dart';
import 'package:huddle/core/providers/global_data_provider.dart';
import 'package:huddle/core/providers/notification_schedule_provider.dart';
import 'package:huddle/core/services/local_notification_service.dart';
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
  await localNotificationService.initialize();
  await Hive.initFlutter();
  try {
    await journalLocalDataSource.init();
  } catch (_) {
    // Corrupted/unreadable box - drop it and continue with an empty local cache rather
    // than blocking app launch.
    await Hive.deleteBoxFromDisk(journalLocalDataSource.boxName);
    await journalLocalDataSource.init();
  }
  try {
    await appDataCache.init();
  } catch (_) {
    await Hive.deleteBoxFromDisk(appDataCache.boxName);
    await appDataCache.init();
  }
  runApp(const HuddleApp());
}

class HuddleApp extends StatefulWidget {
  const HuddleApp({super.key});

  @override
  State<HuddleApp> createState() => _HuddleAppState();
}

class _HuddleAppState extends State<HuddleApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    sessionExpiredNotifier.addListener(_handleSessionExpired);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    sessionExpiredNotifier.removeListener(_handleSessionExpired);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final context = navigatorKey.currentContext;
      context?.read<NotificationScheduleProvider>().refresh();
      context?.read<GlobalDataProvider>().syncIfStale();
    }
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
