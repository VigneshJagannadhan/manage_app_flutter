import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/providers/global_data_provider.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/core/themes/constants/app_spacing.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/auth/screens/sign_in_screen.dart';
import 'package:huddle/features/group/screens/groups_screen.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/settings/providers/settings_provider.dart';
import 'package:huddle/features/settings/providers/theme_provider.dart';
import 'package:huddle/features/settings/screens/customise_app_screen.dart';
import 'package:huddle/features/settings/screens/profile_edit_screen.dart';
import 'package:huddle/features/settings/services/health_service.dart';
import 'package:huddle/features/settings/widgets/profile_header.dart';
import 'package:huddle/features/shared/widgets/app_body_column.dart';
import 'package:huddle/features/shared/widgets/app_button.dart';
import 'package:huddle/features/shared/widgets/app_scaffold.dart';
import 'package:huddle/features/shared/widgets/screen_appbar.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null && !profileProvider.isLoading) {
      profileProvider.loadProfile();
    }
  }

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
    context.read<GlobalDataProvider>().resetAllData();
    navigationService.pushAndRemoveUntil(context, const SignInScreen());
  }

  Future<void> _openGroups(BuildContext context) {
    return navigationService.push(context, const GroupsScreen());
  }

  Future<void> _openEditProfile(BuildContext context) {
    return navigationService.push(context, const ProfileEditScreen());
  }

  Future<void> _openCustomiseApp(BuildContext context) {
    return navigationService.push(context, const CustomiseAppScreen());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final result = provider.healthCheckResult;
    final error = provider.healthCheckError;
    final isSigningOut = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    return AppBodyColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ProfileHeader(profile: profileProvider.profile, isLoading: profileProvider.isLoading, onEdit: () => _openEditProfile(context)),
        AppButton.primary(label: AppStrings.groups, onPressed: () => _openGroups(context)),
        AppButton.secondary(label: AppStrings.customiseTheApp, onPressed: () => _openCustomiseApp(context)),

        AppButton.destructive(label: AppStrings.logOut, onPressed: isSigningOut ? null : () => _signOut(context)),

        Semantics(
          toggled: themeProvider.isDarkMode,
          label: AppStrings.darkMode,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BodyText.medium(AppStrings.darkMode),
              Switch.adaptive(value: themeProvider.isDarkMode, onChanged: themeProvider.setDarkMode),
            ],
          ),
        ),

        if (provider.showDebugStuff) ...[
          AppButton.primary(
            label: provider.isCheckingHealth ? AppStrings.checkingServerHealth : AppStrings.checkServerHealth,
            onPressed: provider.isCheckingHealth ? null : () => context.read<SettingsProvider>().checkServerHealth(),
          ),
          if (result != null)
            BodyText.medium(
              'Status: ${result.status}\nUptime: ${result.uptime.toStringAsFixed(2)}s\nDB: ${result.db}',
              color: context.appTheme.successColor,
            ),
          if (error != null) BodyText.medium(AppStrings.serverDown, color: Theme.of(context).colorScheme.error),
        ],

        Spacer(),
        InkWell(
          onDoubleTap: () => provider.toggleDebugStuff(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Align(
            alignment: Alignment.center,
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version;
                return BodyText.small(
                  version == null ? '' : '${AppStrings.appVersion}: $version',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                );
              },
            ),
          ),
        ),
        SizedBox(height: AppSpacing.space20),
      ],
    );
  }
}
