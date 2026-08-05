import 'package:flutter/material.dart';
import 'package:manage_app/core/constants/app_constants.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/screens/sign_in_screen.dart';
import 'package:manage_app/features/group/screens/groups_screen.dart';
import 'package:manage_app/features/settings/providers/settings_provider.dart';
import 'package:manage_app/features/settings/providers/theme_provider.dart';
import 'package:manage_app/features/settings/services/health_service.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(healthService: healthService),
      child: const AppScaffold(
        appBar: ScreenAppBar(title: AppStrings.settings),
        body: _SettingsBody(),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    navigationService.pushAndRemoveUntil(context, const SignInScreen());
  }

  Future<void> _openGroups(BuildContext context) {
    return navigationService.push(context, const GroupsScreen());
  }

  String get appVersion => '${AppStrings.appVersion}: ${AppConstants.appVersion}';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final result = provider.healthCheckResult;
    final error = provider.healthCheckError;
    final isSigningOut = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();

    return AppBodyColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Semantics(
          toggled: themeProvider.isDarkMode,
          label: AppStrings.darkMode,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(AppStrings.darkMode),
              Switch.adaptive(value: themeProvider.isDarkMode, onChanged: themeProvider.setDarkMode),
            ],
          ),
        ),
        AppButton.primary(label: AppStrings.groups, onPressed: () => _openGroups(context)),
        if (provider.showDebugStuff)
          AppButton.primary(
            label: provider.isCheckingHealth ? AppStrings.checkingServerHealth : AppStrings.checkServerHealth,
            onPressed: provider.isCheckingHealth ? null : () => context.read<SettingsProvider>().checkServerHealth(),
          ),
        if (result != null)
          Text(
            'Status: ${result.status}\nUptime: ${result.uptime.toStringAsFixed(2)}s\nDB: ${result.db}',
            style: context.appTheme.bodyMedium?.copyWith(color: Colors.green.shade700),
          ),
        if (error != null) Text(AppStrings.serverDown, style: context.appTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
        AppButton.destructive(label: AppStrings.logOut, onPressed: isSigningOut ? null : () => _signOut(context)),
        InkWell(
          onDoubleTap: () => provider.toggleDebugStuff(),
          child: Align(
            alignment: Alignment.center,
            child: Text(appVersion, style: context.appTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }
}
