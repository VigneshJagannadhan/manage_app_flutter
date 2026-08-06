import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/settings_avatar_button.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.journalTab,
        showBackButton: false,
        actions: const [SettingsAvatarButton()],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            BodyText.large(AppStrings.journalComingSoon, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
