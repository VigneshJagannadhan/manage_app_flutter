import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
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
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';
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
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _openCreateExpense(context),
        child: const AppSvgIcon(SvgIcons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = context.appTheme;
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
          padding: EdgeInsets.all(theme.horizontalMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BodyText.medium(
                provider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.spacingMedium),
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
        SizedBox(height: theme.spacingMedium),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.horizontalMargin),
          child: SegmentedButton<bool>(
            expandedInsets: EdgeInsets.zero,
            segments: [
              ButtonSegment(value: false, label: Text(groupProvider.activeGroup?.name ?? AppStrings.thisGroup)),
              const ButtonSegment(value: true, label: Text(AppStrings.allGroups)),
            ],
            selected: {provider.showAllGroups},
            onSelectionChanged: (selection) =>
                provider.toggleShowAllGroups(selection.first),
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
    final theme = context.appTheme;
    final recentExpenses = provider.recentExpenses();

    return ListView(
      padding: EdgeInsets.all(theme.horizontalMargin),
      children: [
        ExpenseSummaryCard(
          totalThisMonth: provider.totalThisMonth,
          essentialAmount: provider.essentialAmountThisMonth,
          nonEssentialAmount: provider.nonEssentialAmountThisMonth,
        ),
        SizedBox(height: theme.spacingMedium),
        ExpenseCategoryBreakdown(
          breakdown: provider.categoryBreakdownThisMonth,
        ),
        SizedBox(height: theme.spacingMedium),
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
            padding: EdgeInsets.only(bottom: theme.listItemGap),
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
    final theme = context.appTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.horizontalMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TitleText.medium(AppStrings.noGroupsYet),
            SizedBox(height: theme.spacingSmall),
            BodyText.medium(
              AppStrings.noActiveGroupMessage,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.spacingMedium),
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
