import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/resources/app_fonts.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/settings/providers/font_provider.dart';
import 'package:huddle/features/shared/widgets/app_body_column.dart';
import 'package:huddle/features/shared/widgets/app_card.dart';
import 'package:huddle/features/shared/widgets/app_scaffold.dart';
import 'package:huddle/features/shared/widgets/screen_appbar.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

class CustomiseAppScreen extends StatelessWidget {
  const CustomiseAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fontProvider = context.watch<FontProvider>();

    return AppScaffold(
      appBar: const ScreenAppBar(title: AppStrings.customiseTheApp),
      scrollable: true,
      body: AppBodyColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          LabelText.large(AppStrings.fontStyleLabel),
          BodyText.small(AppStrings.fontStyleDescription),
          for (final option in AppFontOption.values)
            _FontOptionCard(option: option, isSelected: fontProvider.font == option, onTap: () => fontProvider.setFont(option)),
        ],
      ),
    );
  }
}

class _FontOptionCard extends StatelessWidget {
  const _FontOptionCard({required this.option, required this.isSelected, required this.onTap});

  final AppFontOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: colorScheme.primary),
          SizedBox(width: theme.spacingMedium),
          Expanded(
            child: Text(
              option.label,
              style: option.textStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
