import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/journal/providers/journal_provider.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

/// Small appbar-action status readout for the journal editor's autosave - there's no
/// manual save button, so this is the only feedback the user gets that a write landed.
class JournalSaveStatusIndicator extends StatelessWidget {
  const JournalSaveStatusIndicator({super.key, required this.status, this.onRetry});

  final JournalSyncStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (status) {
      JournalSyncStatus.idle || JournalSyncStatus.savedLocally => const SizedBox.shrink(),
      JournalSyncStatus.syncing => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.outline)),
      ),
      JournalSyncStatus.synced => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: LabelText.small(AppStrings.saved, color: colorScheme.outline),
      ),
      JournalSyncStatus.error => TextButton(
        onPressed: onRetry,
        child: LabelText.small(AppStrings.couldNotSaveEntry, color: colorScheme.error),
      ),
    };
  }
}
