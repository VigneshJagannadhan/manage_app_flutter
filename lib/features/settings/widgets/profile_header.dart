import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/auth/models/user_model.dart';
import 'package:manage_app/features/shared/widgets/app_card.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile, required this.isLoading, required this.onEdit});

  final UserModel? profile;
  final bool isLoading;
  final VoidCallback onEdit;

  String get _initials {
    final name = profile?.name.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    final firstInitial = parts.first.substring(0, 1);
    final lastInitial = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (firstInitial + lastInitial).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      cardTap: false,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: TitleText.large(_initials, color: colorScheme.onPrimaryContainer),
          ),
          SizedBox(width: theme.spacingMedium ?? 16),
          Expanded(
            child: isLoading && profile == null
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                : TitleText.medium(profile?.name ?? '', overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editProfileTooltip,
            onPressed: profile == null ? null : onEdit,
          ),
        ],
      ),
    );
  }
}
