import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
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
  static const _minimumSplashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _goToHome();
  }

  Future<void> _goToHome() async {
    final stopwatch = Stopwatch()..start();
    await context.read<AuthProvider>().restoreSession();
    stopwatch.stop();

    if (!mounted) return;

    final remainingTime = _minimumSplashDuration - stopwatch.elapsed;
    if (remainingTime.isNegative == false) {
      await Future.delayed(remainingTime);
    }

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
            AppImage.asset(source: AppImages.appLogo, width: 120, height: 120),
            SizedBox(height: 32),
            CircularProgressIndicator.adaptive(backgroundColor: context.appTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
