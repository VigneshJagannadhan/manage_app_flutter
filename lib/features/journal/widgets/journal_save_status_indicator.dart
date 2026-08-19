import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';

enum JournalSaveStatus { idle, saving, saved, error }

/// Small appbar-action status readout for the journal editor's autosave - there's no
/// manual save button, so this is the only feedback the user gets that a write landed.
class JournalSaveStatusIndicator extends StatelessWidget {
  const JournalSaveStatusIndicator({super.key, required this.status, this.onRetry});

  final JournalSaveStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (status) {
      JournalSaveStatus.idle => const SizedBox.shrink(),
      JournalSaveStatus.saving => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.outline)),
      ),
      JournalSaveStatus.saved => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: LabelText.small(AppStrings.saved, color: colorScheme.outline),
      ),
      JournalSaveStatus.error => TextButton(
        onPressed: onRetry,
        child: LabelText.small(AppStrings.couldNotSaveEntry, color: colorScheme.error),
      ),
    };
  }
}
