import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/settings_avatar_button.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.remindersTab,
        showBackButton: false,
        actions: const [SettingsAvatarButton()],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_outlined, size: 48, color: colorScheme.outline),
            SizedBox(height: theme.spacingMedium),
            BodyText.large(AppStrings.remindersComingSoon, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
