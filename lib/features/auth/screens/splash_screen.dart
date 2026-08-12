import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/providers/app_provider.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/screens/sign_in_screen.dart';
import 'package:manage_app/features/home/screens/home_screen.dart';
import 'package:manage_app/features/shared/widgets/app_image.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _loadingTextIndex = 0;
  Timer? _loadingTextTimer;

  @override
  void initState() {
    super.initState();
    _goToHome();
    _loadingTextTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_loadingTextIndex >= loadingTexts.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _loadingTextIndex++);
    });
  }

  @override
  void dispose() {
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  Future<void> _goToHome() async {
    await context.read<AuthProvider>().restoreSession();
    if (!mounted) return;
    await context.read<AppProvider>().loadAllData();
    if (!mounted) return;
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    navigationService.pushReplacement(
      context,
      isAuthenticated ? HomeScreen() : const SignInScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage.asset(source: AppImages.appLogo, width: 120, height: 120),
            SizedBox(height: 32),
            CircularProgressIndicator.adaptive(
              backgroundColor: context.appTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(_getLoadingText()),
          ],
        ),
      ),
    );
  }

  String _getLoadingText() => loadingTexts[_loadingTextIndex];
}

List<String> loadingTexts = [
  'Starting the server...',
  'Loading app data...',
  'Almost there...',
];
