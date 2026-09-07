import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/providers/global_data_provider.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

/// A thin strip shown under the appbar (via [AppScaffold.syncBanner]) while
/// [GlobalDataProvider] is refreshing from the network in the background. No error state -
/// on a failed sync the banner just disappears and whatever was already on screen (cached
/// or previously-synced data) stays put.
///
/// Renders nothing if there's no [GlobalDataProvider] above it in the tree, rather than
/// throwing - screens that use this are also exercised in narrower widget tests that don't
/// wire up the full app-wide provider graph, and this banner is purely decorative.
class GlobalSyncBanner extends StatelessWidget {
  const GlobalSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSyncing;
    try {
      isSyncing = context.watch<GlobalDataProvider>().isSyncing;
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    if (!isSyncing) return const SizedBox.shrink();

    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: theme.horizontalMargin, vertical: theme.spacingSmall),
      color: colorScheme.surfaceContainer,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.outline)),
          SizedBox(width: theme.spacingSmall),
          LabelText.small(AppStrings.syncing, color: colorScheme.outline),
        ],
      ),
    );
  }
}
