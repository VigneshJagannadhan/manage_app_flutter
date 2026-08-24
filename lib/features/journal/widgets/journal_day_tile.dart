import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/journal/providers/journal_provider.dart';
import 'package:huddle/features/shared/widgets/app_card.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';

/// One row in the journal feed for a day that isn't today-with-no-entry (that case gets
/// [CreateTodayCard] instead). Renders either a content preview or a muted "missing" state -
/// both tappable, both open the same editor screen.
class JournalDayTile extends StatelessWidget {
  const JournalDayTile({super.key, required this.slot, required this.onTap});

  final JournalDaySlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final entry = slot.entry;
    final dateLabel = slot.date.isToday ? AppStrings.today : slot.date.formattedShortDate;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacingXSmall,
        children: [
          LabelText.small(
            dateLabel.toUpperCase(),
            color: entry == null ? colorScheme.outline : colorScheme.primary,
            style: const TextStyle(letterSpacing: 0.5),
          ),
          BodyText.medium(
            entry == null || entry.content.trim().isEmpty ? AppStrings.noEntryLabel : entry.content,
            color: entry == null ? colorScheme.outline : colorScheme.onSurface,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
