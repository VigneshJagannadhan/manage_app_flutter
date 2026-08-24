import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/shared/widgets/app_button.dart';
import 'package:huddle/features/shared/widgets/app_card.dart';
import 'package:huddle/features/shared/widgets/text/title_text.dart';

/// Prompt shown in place of a tile when today has no entry yet.
class CreateTodayCard extends StatelessWidget {
  const CreateTodayCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return AppCard(
      cardTap: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacingSmall,
        children: [
          TitleText.medium(AppStrings.todaysEntryPrompt),
          AppButton.primary(label: AppStrings.writeTodaysEntry, onPressed: onTap),
        ],
      ),
    );
  }
}
