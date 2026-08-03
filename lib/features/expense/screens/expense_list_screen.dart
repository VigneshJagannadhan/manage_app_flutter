import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/expense/screens/expense_form_screen.dart';
import 'package:manage_app/features/expense/widgets/expense_tile.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/group/screens/groups_screen.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/settings_avatar_button.dart';
import 'package:provider/provider.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  Future<void> _openGroups(BuildContext context) {
    return navigationService.push(context, const GroupsScreen());
  }

  Future<void> _openCreateExpense(BuildContext context) {
    if (context.read<GroupProvider>().activeGroupId == null) {
      return _openGroups(context);
    }
    return navigationService.push<ExpenseChangeResult>(context, const ExpenseFormScreen());
  }

  Future<void> _openEditExpense(BuildContext context, ExpenseModel expense) {
    return navigationService.push<ExpenseChangeResult>(context, ExpenseFormScreen(expense: expense));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.manageYourExpenses,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: AppStrings.groupsTooltip,
            onPressed: () => _openGroups(context),
          ),
          const SettingsAvatarButton(),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _openCreateExpense(context),
        child: const AppSvgIcon(SvgIcons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final provider = context.watch<ExpenseProvider>();

    if (groupProvider.groups.isEmpty && !groupProvider.isLoading) {
      return _NoGroupsPrompt(onGoToGroups: () => _openGroups(context));
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton.secondary(label: AppStrings.retry, onPressed: provider.loadExpenses),
            ],
          ),
        ),
      );
    }

    final expenses = provider.expenses;
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
          child: expenses.isEmpty
              ? const Center(child: Text(AppStrings.noExpensesYet))
              : RefreshIndicator(
                  onRefresh: provider.loadExpenses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExpenseTile(
                        expense: expenses[index],
                        groupName: provider.showAllGroups ? groupProvider.nameForGroup(expenses[index].groupId) : null,
                        onTap: () => _openEditExpense(context, expenses[index]),
                        onEdit: () => _openEditExpense(context, expenses[index]),
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
            Text(AppStrings.noGroupsYet, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(AppStrings.noActiveGroupMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton.primary(label: AppStrings.goToGroups, onPressed: onGoToGroups),
          ],
        ),
      ),
    );
  }
}
