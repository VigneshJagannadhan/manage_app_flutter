import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/screens/sign_in_screen.dart';
import 'package:manage_app/features/home/screens/home_screen.dart';
import 'package:manage_app/features/shared/widgets/app_animated_logo.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Future<void> _restoreSession;

  @override
  void initState() {
    super.initState();
    _restoreSession = context.read<AuthProvider>().restoreSession();
  }

  Future<void> _goToHome() async {
    await _restoreSession;
    if (!mounted) return;
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    navigationService.pushReplacement(context, isAuthenticated ? HomeScreen() : const SignInScreen());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAnimatedLogo(
              logoText: AppStrings.appName,
              initialScale: 2.5,
              fontSize: 48,
              fontWeight: FontWeight.w400,
              textColor: context.appTheme.primaryColor,
              onAnimationComplete: _goToHome,
            ),
            SizedBox(height: 32),
            CircularProgressIndicator.adaptive(backgroundColor: context.appTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
