import 'package:flutter/material.dart';
import 'package:huddle/core/enums/expense_enums.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/currency_extension.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/extensions/string_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/expense/models/expense_model.dart';
import 'package:huddle/features/expense/screens/expense_form_screen.dart';
import 'package:huddle/features/expense/widgets/expense_category_style.dart';
import 'package:huddle/features/group/models/group_member_model.dart';
import 'package:huddle/features/group/providers/group_provider.dart';
import 'package:huddle/features/shared/widgets/app_body_column.dart';
import 'package:huddle/features/shared/widgets/app_scaffold.dart';
import 'package:huddle/features/shared/widgets/info_card.dart';
import 'package:huddle/features/shared/widgets/screen_appbar.dart';
import 'package:huddle/features/shared/widgets/text/headline_text.dart';
import 'package:provider/provider.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({super.key, required this.expense});

  final ExpenseModel expense;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late ExpenseModel _expense = widget.expense;
  ExpenseChangeResult? _pendingResult;

  String get title => _expense.title ?? '';
  ExpenseCategory? get category => _expense.category;
  String get categoryName => category?.name.toTitleCase ?? '';
  String get displayAmount => _expense.amount.toCurrencyString();
  String get formattedDate => _expense.date?.formattedDateTime ?? '';

  @override
  void initState() {
    super.initState();
    final groupId = _expense.groupId;
    if (groupId == null) return;
    final groupProvider = context.read<GroupProvider>();
    if (groupProvider.membersFor(groupId).isEmpty) {
      groupProvider.loadMembers(groupId);
    }
  }

  GroupMemberModel? _findMember(String userId, List<GroupMemberModel> members) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  String _memberLabel(
    String userId,
    List<GroupMemberModel> members,
    String? currentUserId,
  ) {
    final name = _findMember(userId, members)?.name ?? userId;
    return userId == currentUserId ? '$name${AppStrings.youSuffix}' : name;
  }

  Future<void> _editExpense() async {
    final result = await navigationService.push<ExpenseChangeResult>(
      context,
      ExpenseFormScreen(expense: _expense),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case ExpenseChangeSaved(:final expense):
        setState(() {
          _expense = expense;
          _pendingResult = result;
        });
      case ExpenseChangeDeleted():
        navigationService.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final groupProvider = context.watch<GroupProvider>();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    final groupId = _expense.groupId;
    final members = groupId != null
        ? groupProvider.membersFor(groupId)
        : const <GroupMemberModel>[];
    final payerId = _expense.payerId;
    final payerLabel = payerId != null
        ? _memberLabel(payerId, members, currentUserId)
        : null;

    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.expenseDetails,
        onBackPressed: () => navigationService.pop(context, _pendingResult),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: AppStrings.editExpenseTooltip,
            onPressed: _editExpense,
          ),
        ],
      ),
      scrollable: true,
      body: AppBodyColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacingMedium,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.appBorderRadius),
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                child: Icon(ExpenseCategoryStyle.iconFor(category), color: Colors.white),
              ),
              SizedBox(width: theme.spacingMedium),
              Expanded(child: HeadlineText.small(title)),
            ],
          ),
          HeadlineText.small(
            displayAmount,
            color: colorScheme.primary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Divider(color: colorScheme.outlineVariant, thickness: 0.5),
          InfoCard(
            children: [
              if (category != null)
                InfoRow(
                  icon: const Icon(Icons.category),
                  label: AppStrings.categoryLabel,
                  value: categoryName,
                ),
              if (_expense.date != null)
                InfoRow(
                  icon: const Icon(Icons.calendar_today),
                  label: AppStrings.dateLabel,
                  value: formattedDate,
                ),
              if (payerLabel != null)
                InfoRow(
                  icon: const Icon(Icons.person),
                  label: AppStrings.payerLabel,
                  value: payerLabel,
                ),
              InfoRow(
                icon: Icon(_expense.essential ? Icons.star : Icons.star_border),
                label: AppStrings.essentialLabel,
                value: _expense.essential ? AppStrings.yes : AppStrings.no,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
