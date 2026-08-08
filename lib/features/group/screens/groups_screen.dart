import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/group_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/group/models/group_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/group/screens/create_group_screen.dart';
import 'package:manage_app/features/group/screens/join_group_screen.dart';
import 'package:manage_app/features/group/widgets/invite_code_view.dart';
import 'package:manage_app/features/shared/widgets/app_bottom_sheet.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_card.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:provider/provider.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _switchTo(BuildContext context, GroupModel group) async {
    final groupProvider = context.read<GroupProvider>();
    if (groupProvider.activeGroupId == group.id) return;
    await groupProvider.setActiveGroup(group.id);
    if (!context.mounted) return;
    context.read<TaskProvider>().loadTasks();
    context.read<ExpenseProvider>().loadExpenses();
  }

  Future<void> _openCreateGroup(BuildContext context) {
    return navigationService.push(context, const CreateGroupScreen());
  }

  Future<void> _openJoinGroup(BuildContext context) {
    return navigationService.push(context, const JoinGroupScreen());
  }

  Future<void> _viewInviteCode(BuildContext context, GroupModel group) {
    return AppBottomSheet.show(
      context,
      title: AppStrings.inviteCodeLabel,
      body: InviteCodeView(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return AppScaffold(
      appBar: ScreenAppBar(title: AppStrings.groups),
      body: _buildBody(context),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(theme.horizontalMargin ?? 16),
        child: Row(
          spacing: theme.spacingMedium ?? 16,
          children: [
            Expanded(
              child: AppButton.secondary(
                label: AppStrings.joinGroup,
                onPressed: () => _openJoinGroup(context),
              ),
            ),
            Expanded(
              child: AppButton.primary(
                label: AppStrings.createGroup,
                onPressed: () => _openCreateGroup(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<GroupProvider>();

    if (provider.isLoading && provider.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.errorMessage != null && provider.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BodyText.medium(
                provider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton.secondary(
                label: AppStrings.retry,
                onPressed: provider.loadGroups,
              ),
            ],
          ),
        ),
      );
    }

    final groups = provider.groups;
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TitleText.medium(AppStrings.noGroupsYet),
              const SizedBox(height: 8),
              BodyText.medium(
                AppStrings.noGroupsSubtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GroupListItem(
              group: group,
              isActive: group.id == provider.activeGroupId,
              onTap: () => _switchTo(context, group),
              onViewInviteCode: () => _viewInviteCode(context, group),
            ),
          );
        },
      ),
    );
  }
}

class _GroupListItem extends StatelessWidget {
  const _GroupListItem({
    required this.group,
    required this.isActive,
    required this.onTap,
    required this.onViewInviteCode,
  });

  final GroupModel group;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onViewInviteCode;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final roleLabel = switch (group.role) {
      GroupRole.owner => AppStrings.owner,
      GroupRole.member => AppStrings.member,
      null => null,
    };

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: colorScheme.primary,
          ),
          SizedBox(width: theme.spacingMedium ?? 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleText.medium(group.name),
                if (roleLabel != null)
                  BodyText.small(
                    roleLabel,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (isActive)
            LabelText.large(
              AppStrings.active,
              color: colorScheme.primary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: AppStrings.viewInviteCodeTooltip,
            onPressed: onViewInviteCode,
          ),
        ],
      ),
    );
  }
}
