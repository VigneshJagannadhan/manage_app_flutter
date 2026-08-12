import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/group/screens/groups_screen.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/settings_avatar_button.dart';
import 'package:manage_app/features/task/models/task_model.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';
import 'package:manage_app/features/task/screens/task_detail_screen.dart';
import 'package:manage_app/features/task/screens/task_form_screen.dart';
import 'package:manage_app/features/task/widgets/task_filter_sheet.dart';
import 'package:manage_app/features/task/widgets/task_tile.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';
import 'package:provider/provider.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  Future<void> _openGroups(BuildContext context) {
    return navigationService.push(context, const GroupsScreen());
  }

  Future<void> _openCreateTask(BuildContext context) {
    if (context.read<GroupProvider>().activeGroupId == null) {
      return _openGroups(context);
    }
    return navigationService.push<TaskChangeResult>(context, const TaskFormScreen());
  }

  Future<void> _openEditTask(BuildContext context, TaskModel task) {
    return navigationService.push<TaskChangeResult>(context, TaskFormScreen(task: task));
  }

  Future<void> _openTaskDetail(BuildContext context, TaskModel task) {
    return navigationService.push<TaskChangeResult>(context, TaskDetailScreen(task: task));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.manageYourTasks,
        showBackButton: false,
        actions: [
          IconButton(icon: const Icon(Icons.tune), tooltip: AppStrings.filterTooltip, onPressed: () => TaskFilterSheet.show(context)),
          const SettingsAvatarButton(),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(heroTag: null, onPressed: () => _openCreateTask(context), child: const AppSvgIcon(SvgIcons.add)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final provider = context.watch<TaskProvider>();

    if (groupProvider.groups.isEmpty && !groupProvider.isLoading) {
      return _NoGroupsPrompt(onGoToGroups: () => _openGroups(context));
    }

    if (provider.isLoading && provider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.errorMessage != null && provider.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BodyText.medium(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton.secondary(label: AppStrings.retry, onPressed: provider.loadTasks),
            ],
          ),
        ),
      );
    }

    final tasks = provider.tasks;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text(AppStrings.thisGroup)),
              ButtonSegment(value: true, label: Text(AppStrings.allGroups)),
            ],
            selected: {provider.showAllGroups},
            onSelectionChanged: (selection) => provider.toggleShowAllGroups(selection.first),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: BodyText.medium(AppStrings.noTasksYet))
              : RefreshIndicator(
                  onRefresh: provider.loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskTile(
                        task: tasks[index],
                        groupName: provider.showAllGroups ? groupProvider.nameForGroup(tasks[index].groupId) : null,
                        onTap: () => _openTaskDetail(context, tasks[index]),
                        onEdit: () => _openEditTask(context, tasks[index]),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _NoGroupsPrompt extends StatelessWidget {
  const _NoGroupsPrompt({required this.onGoToGroups});

  final VoidCallback onGoToGroups;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TitleText.medium(AppStrings.noGroupsYet),
            const SizedBox(height: 8),
            BodyText.medium(AppStrings.noActiveGroupMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton.primary(label: AppStrings.goToGroups, onPressed: onGoToGroups),
          ],
        ),
      ),
    );
  }
}
