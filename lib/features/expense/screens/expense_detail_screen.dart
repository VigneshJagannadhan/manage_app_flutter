import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/currency_extension.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/themes/constants/app_spacing.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/expense/screens/expense_form_screen.dart';
import 'package:manage_app/features/expense/widgets/expense_category_style.dart';
import 'package:manage_app/features/group/models/group_member_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/headline_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';
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
        spacing: theme.spacingMedium ?? 16,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    (theme.appBorderRadius ?? 12) - AppSpacing.space4,
                  ),
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                child: Icon(ExpenseCategoryStyle.iconFor(category), color: Colors.white),
              ),
              SizedBox(width: theme.spacingMedium ?? 16),
              Expanded(child: HeadlineText.small(title)),
            ],
          ),
          HeadlineText.small(
            displayAmount,
            color: colorScheme.primary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Divider(color: colorScheme.outlineVariant),
          if (category != null)
            _DetailRow(
              icon: Icon(Icons.category, size: 18, color: colorScheme.outline),
              label: AppStrings.categoryLabel,
              value: categoryName,
            ),
          if (_expense.date != null)
            _DetailRow(
              icon: Icon(
                Icons.calendar_today,
                size: 18,
                color: colorScheme.outline,
              ),
              label: AppStrings.dateLabel,
              value: formattedDate,
            ),
          if (payerLabel != null)
            _DetailRow(
              icon: Icon(Icons.person, size: 18, color: colorScheme.outline),
              label: AppStrings.payerLabel,
              value: payerLabel,
            ),
          SizedBox(height: theme.spacingSmall ?? 8),
          TitleText.small(AppStrings.splitDetailsLabel),
          if (_expense.splits.isEmpty)
            BodyText.medium(
              AppStrings.noSplitsRecorded,
              color: colorScheme.outline,
            )
          else
            for (final split in _expense.splits)
              _SplitRow(
                label: _memberLabel(split.userId, members, currentUserId),
                amount: split.amountOwed,
              ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        icon,
        SizedBox(width: theme.spacingSmall ?? 8),
        BodyText.medium('$label: ', color: colorScheme.outline),
        BodyText.medium(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: BodyText.medium(label)),
        BodyText.medium(
          amount.toCurrencyString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
