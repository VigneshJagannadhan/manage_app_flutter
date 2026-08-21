import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/expense/screens/all_expenses_screen.dart';
import 'package:manage_app/features/expense/screens/expense_detail_screen.dart';
import 'package:manage_app/features/expense/screens/expense_form_screen.dart';
import 'package:manage_app/features/expense/widgets/expense_category_breakdown.dart';
import 'package:manage_app/features/expense/widgets/expense_summary_card.dart';
import 'package:manage_app/features/expense/widgets/expense_tile.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/group/screens/groups_screen.dart';
import 'package:manage_app/features/group/widgets/group_scope_toggle.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/create_fab.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/settings_avatar_button.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';
import 'package:provider/provider.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({super.key});

  Future<void> _openGroups(BuildContext context) {
    return navigationService.push(context, const GroupsScreen());
  }

  Future<void> _openCreateExpense(BuildContext context) {
    if (context.read<GroupProvider>().activeGroupId == null) {
      return _openGroups(context);
    }
    return navigationService.push<ExpenseChangeResult>(
      context,
      const ExpenseFormScreen(),
    );
  }

  Future<void> _openExpenseDetail(BuildContext context, ExpenseModel expense) {
    return navigationService.push<ExpenseChangeResult>(
      context,
      ExpenseDetailScreen(expense: expense),
    );
  }

  Future<void> _openAllExpenses(BuildContext context) {
    return navigationService.push(context, const AllExpensesScreen());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.manageYourExpenses,
        showBackButton: false,
        actions: [const SettingsAvatarButton()],
      ),
      body: _buildBody(context),
      floatingActionButton: CreateFab(label: AppStrings.createExpense, onPressed: () => _openCreateExpense(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final provider = context.watch<ExpenseProvider>();

    if (groupProvider.groups.isEmpty && !groupProvider.isLoading) {
      return _NoGroupsPrompt(onGoToGroups: () => _openGroups(context));
    }

    if (provider.isLoading && provider.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.errorMessage != null && provider.expenses.isEmpty) {
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
                onPressed: provider.loadExpenses,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GroupScopeToggle(
            activeGroupLabel: groupProvider.activeGroup?.name ?? AppStrings.thisGroup,
            showAllGroups: provider.showAllGroups,
            onChanged: provider.toggleShowAllGroups,
          ),
        ),
        Expanded(
          child: provider.expenses.isEmpty
              ? const Center(child: BodyText.medium(AppStrings.noExpensesYet))
              : RefreshIndicator(
                  onRefresh: provider.loadExpenses,
                  child: _DashboardContent(
                    provider: provider,
                    onSeeAll: () => _openAllExpenses(context),
                    onTapExpense: (expense) =>
                        _openExpenseDetail(context, expense),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.provider,
    required this.onSeeAll,
    required this.onTapExpense,
  });

  final ExpenseProvider provider;
  final VoidCallback onSeeAll;
  final ValueChanged<ExpenseModel> onTapExpense;

  @override
  Widget build(BuildContext context) {
    final recentExpenses = provider.recentExpenses();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        ExpenseSummaryCard(
          totalThisMonth: provider.totalThisMonth,
          essentialAmount: provider.essentialAmountThisMonth,
          nonEssentialAmount: provider.nonEssentialAmountThisMonth,
        ),
        const SizedBox(height: 16),
        ExpenseCategoryBreakdown(
          breakdown: provider.categoryBreakdownThisMonth,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TitleText.small(AppStrings.recentLabel),
            TextButton(
              onPressed: onSeeAll,
              child: const Text(AppStrings.seeAll),
            ),
          ],
        ),
        for (final expense in recentExpenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExpenseTile(
              expense: expense,
              groupName: provider.showAllGroups
                  ? context.read<GroupProvider>().nameForGroup(expense.groupId)
                  : null,
              onTap: () => onTapExpense(expense),
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
            BodyText.medium(
              AppStrings.noActiveGroupMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: AppStrings.goToGroups,
              onPressed: onGoToGroups,
            ),
          ],
        ),
      ),
    );
  }
}
