import 'package:flutter/material.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/features/expense/models/expense_model.dart';
import 'package:huddle/features/expense/providers/expense_provider.dart';
import 'package:huddle/features/expense/screens/expense_detail_screen.dart';
import 'package:huddle/features/expense/screens/expense_form_screen.dart';
import 'package:huddle/features/expense/widgets/expense_filter_sheet.dart';
import 'package:huddle/features/expense/widgets/expense_sort_sheet.dart';
import 'package:huddle/features/expense/widgets/expense_tile.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/shared/widgets/app_scaffold.dart';
import 'package:huddle/features/shared/widgets/app_text_field.dart';
import 'package:huddle/features/shared/widgets/screen_appbar.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

/// Drill-in screen listing every expense (in the active group scope) with
/// search, category, date-range, and sort controls.
class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  late final _searchController = TextEditingController(text: context.read<ExpenseProvider>().searchQuery);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: provider.dateRangeFilter,
    );
    if (picked != null) provider.setDateRangeFilter(picked);
  }

  Future<void> _openExpenseDetail(BuildContext context, ExpenseModel expense) {
    return navigationService.push<ExpenseChangeResult>(context, ExpenseDetailScreen(expense: expense));
  }

  static String _dateRangeLabel(DateTimeRange? range) {
    if (range == null) return AppStrings.dateRange;
    return '${range.start.formattedShortDate} - ${range.end.formattedShortDate}';
  }

  /// "Today, 10 Aug" for today, "9 Aug" otherwise - grouping is only meaningful
  /// while the list is date-sorted, so this is only used in that case.
  static String _sectionLabel(DateTime date) => date.isToday ? '${AppStrings.today}, ${date.formattedShortDate}' : date.formattedShortDate;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const ScreenAppBar(title: AppStrings.allExpensesTitle),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = context.appTheme;
    final provider = context.watch<ExpenseProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final expenses = provider.filteredExpenses;
    final isDateSorted = provider.sortOption == ExpenseSortOption.newest || provider.sortOption == ExpenseSortOption.oldest;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(theme.horizontalMargin, theme.verticalMargin, theme.horizontalMargin, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _searchController,
                hint: AppStrings.searchExpensesHint,
                prefixIcon: Icons.search,
                onChanged: provider.setSearchQuery,
              ),
              SizedBox(height: theme.spacingMedium),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.filter_list, size: 16),
                      label: const Text(AppStrings.filter),
                      onPressed: () => ExpenseFilterSheet.show(context),
                    ),
                    SizedBox(width: theme.spacingSmall),
                    ActionChip(
                      avatar: const Icon(Icons.sort, size: 16),
                      label: const Text(AppStrings.sort),
                      onPressed: () => ExpenseSortSheet.show(context),
                    ),
                    SizedBox(width: theme.spacingSmall),
                    ActionChip(
                      avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(_dateRangeLabel(provider.dateRangeFilter)),
                      onPressed: () => _pickDateRange(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: expenses.isEmpty
              ? const Center(child: BodyText.medium(AppStrings.noExpensesYet))
              : ListView.builder(
                  padding: EdgeInsets.all(theme.horizontalMargin),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final date = expense.date;
                    final showHeader = isDateSorted && date != null && (index == 0 || !date.isSameDate(expenses[index - 1].date ?? date));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          if (index != 0) SizedBox(height: theme.spacingSmall),
                          Padding(
                            padding: EdgeInsets.only(bottom: theme.spacingSmall),
                            child: LabelText.small(_sectionLabel(date), color: Theme.of(context).colorScheme.outline),
                          ),
                        ],
                        Padding(
                          padding: EdgeInsets.only(bottom: theme.listItemGap),
                          child: ExpenseTile(
                            expense: expense,
                            groupName: groupProvider.showAllGroups ? groupProvider.nameForGroup(expense.groupId) : null,
                            onTap: () => _openExpenseDetail(context, expense),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
