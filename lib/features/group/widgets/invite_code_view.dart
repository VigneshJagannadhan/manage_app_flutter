import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/group/models/group_model.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:share_plus/share_plus.dart' show Share;

class InviteCodeView extends StatelessWidget {
  const InviteCodeView({super.key, required this.group});

  final GroupModel group;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: group.inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.inviteCodeCopied)));
  }

  Future<void> _shareCode() {
    return Share.share('Join my group "${group.name}" on TaskEasy with invite code: ${group.inviteCode}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBodyColumn(
      padding: EdgeInsets.zero,
      spacing: 16,
      children: [
        Text(AppStrings.shareThisCode, textAlign: TextAlign.center),
        Container(
          padding: EdgeInsets.symmetric(horizontal: theme.horizontalMargin ?? 24, vertical: theme.spacingLarge ?? 24),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 12),
          ),
          child: Text(
            group.inviteCode,
            style: theme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer, letterSpacing: 4, fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          spacing: theme.spacingMedium ?? 16,
          children: [
            Expanded(
              child: AppButton.secondary(label: AppStrings.copy, onPressed: () => _copyCode(context)),
            ),
            Expanded(
              child: AppButton.secondary(label: AppStrings.share, onPressed: _shareCode),
            ),
          ],
        ),
      ],
    );
  }
}
