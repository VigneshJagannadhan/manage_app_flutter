import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/expense_enums.dart';
import 'package:manage_app/core/extensions/string_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/expense_service.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/expense/models/expense_model.dart';
import 'package:manage_app/features/expense/models/expense_split_model.dart';
import 'package:manage_app/features/expense/providers/expense_provider.dart';
import 'package:manage_app/features/group/models/group_member_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_date_picker.dart';
import 'package:manage_app/features/shared/widgets/app_dropdown_field.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/member_dropdown_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:manage_app/features/shared/widgets/text/title_text.dart';
import 'package:provider/provider.dart';

/// Result of pushing [ExpenseFormScreen]: either the expense was saved, or -
/// when editing - it was deleted instead. A plain nullable [ExpenseModel]
/// can't carry the delete case since there's no updated expense to return.
sealed class ExpenseChangeResult {
  const ExpenseChangeResult();
}

class ExpenseChangeSaved extends ExpenseChangeResult {
  const ExpenseChangeSaved(this.expense);

  final ExpenseModel expense;
}

class ExpenseChangeDeleted extends ExpenseChangeResult {
  const ExpenseChangeDeleted(this.id);

  final String id;
}

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  /// When set, the screen edits this expense instead of creating a new one.
  final ExpenseModel? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.expense?.title);
  late final _amountController = TextEditingController(text: widget.expense?.amount?.toStringAsFixed(2));

  bool get _isEditing => widget.expense != null;

  late ExpenseCategory? _selectedCategory = widget.expense?.category;
  late DateTime? _date = widget.expense?.date ?? DateTime.now();
  bool _isSubmitting = false;
  bool _isDeleting = false;

  GroupMemberModel? _selectedPayer;
  final Set<String> _checkedMemberIds = {};
  final Map<String, TextEditingController> _splitControllers = {};

  bool get _isBusy => _isSubmitting || _isDeleting;

  // Payer/splits only apply at creation - the API doesn't support editing them on an
  // existing expense yet, so this screen only offers title/amount/category/date when editing.
  String? get _activeGroupId => _isEditing ? null : context.read<GroupProvider>().activeGroupId;

  @override
  void initState() {
    super.initState();
    final groupId = _activeGroupId;
    if (groupId == null) return;
    final groupProvider = context.read<GroupProvider>();
    final existingMembers = groupProvider.membersFor(groupId);
    if (existingMembers.isNotEmpty) {
      _applyDefaultPayer(existingMembers);
    } else {
      groupProvider.loadMembers(groupId).then((_) {
        if (!mounted) return;
        setState(() => _applyDefaultPayer(groupProvider.membersFor(groupId)));
      });
    }
  }

  void _applyDefaultPayer(List<GroupMemberModel> members) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    for (final member in members) {
      if (member.userId == currentUserId) {
        _selectedPayer = member;
        return;
      }
    }
  }

  TextEditingController _splitControllerFor(String userId) => _splitControllers.putIfAbsent(userId, TextEditingController.new);

  void _toggleSplitMember(String userId, bool checked) {
    setState(() {
      if (checked) {
        _checkedMemberIds.add(userId);
      } else {
        _checkedMemberIds.remove(userId);
        _splitControllers[userId]?.clear();
      }
    });
  }

  void _splitEqually() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.amountRequired)));
      return;
    }
    if (_checkedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.selectAtLeastOneMember)));
      return;
    }

    final ids = _checkedMemberIds.toList();
    final totalCents = (amount * 100).round();
    final baseShareCents = totalCents ~/ ids.length;
    final remainderCents = totalCents % ids.length;
    setState(() {
      for (var i = 0; i < ids.length; i++) {
        final cents = baseShareCents + (i < remainderCents ? 1 : 0);
        _splitControllerFor(ids[i]).text = (cents / 100).toStringAsFixed(2);
      }
    });
  }

  /// Returns the split entries, or null (with a SnackBar shown) if the entered amounts
  /// don't add up to the total - purely a client-side sanity check, not a backend rule.
  List<ExpenseSplit>? _collectSplits(double totalAmount) {
    if (_checkedMemberIds.isEmpty) return const [];

    final splits = <ExpenseSplit>[];
    for (final userId in _checkedMemberIds) {
      final owed = double.tryParse(_splitControllerFor(userId).text.trim()) ?? 0;
      splits.add(ExpenseSplit(userId: userId, amountOwed: owed));
    }
    final sum = splits.fold<double>(0, (total, split) => total + split.amountOwed);
    if ((sum - totalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.splitsMismatchError)));
      return null;
    }
    return splits;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.categoryRequired)));
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final splits = _isEditing ? const <ExpenseSplit>[] : _collectSplits(amount);
    if (splits == null) return;

    setState(() => _isSubmitting = true);
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final expense = _isEditing
          ? await expenseProvider.updateExpense(id: widget.expense!.id!, title: title, amount: amount, category: _selectedCategory!, date: _date!)
          : await expenseProvider.createExpense(
              ExpenseModel(
                title: title,
                amount: amount,
                category: _selectedCategory!,
                date: _date!,
                createdAt: null,
                groupId: _activeGroupId,
                payerId: _selectedPayer?.userId,
                splits: splits,
              ),
            );
      if (!mounted) return;
      if (expense == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.couldNotCreateExpense)));
        return;
      }
      navigationService.pop(context, ExpenseChangeSaved(expense));
    } on ExpenseServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteExpense),
        content: const Text(AppStrings.deleteExpenseConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: LabelText.large(AppStrings.delete, color: Theme.of(dialogContext).colorScheme.error),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final id = widget.expense!.id!;
      await context.read<ExpenseProvider>().deleteExpense(id);
      if (!mounted) return;
      navigationService.pop(context, ExpenseChangeDeleted(id));
    } on ExpenseServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(title: _isEditing ? AppStrings.editExpenseTitle : AppStrings.createExpense),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AppBodyColumn(
            spacing: 16,
            children: [
              AppTextField(
                label: AppStrings.expenseTitleLabel,
                controller: _titleController,
                enabled: !_isBusy,
                validator: (value) => (value == null || value.trim().isEmpty) ? AppStrings.expenseTitleRequired : null,
              ),
              AppTextField(
                label: AppStrings.amountLabel,
                controller: _amountController,
                enabled: !_isBusy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return AppStrings.amountRequired;
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) return AppStrings.invalidAmount;
                  return null;
                },
              ),
              AppDropdownField<ExpenseCategory>(
                hint: AppStrings.categoryLabel,
                value: _selectedCategory,
                items: ExpenseCategory.values,
                itemLabelBuilder: (item) => item.name.toTitleCase,
                enabled: !_isBusy,
                onChanged: (value) {
                  _selectedCategory = value;
                  setState(() {});
                },
              ),
              AppDatePicker(
                label: AppStrings.dateLabel,
                value: _date,
                enabled: !_isBusy,
                lastDate: DateTime.now(),
                validator: (value) => value == null ? AppStrings.expenseDateRequired : null,
                onChanged: (value) => _date = value,
              ),
              if (!_isEditing) ..._buildGroupFields(),
              AppButton.primary(
                label: _isSubmitting
                    ? (_isEditing ? AppStrings.saving : AppStrings.creating)
                    : (_isEditing ? AppStrings.saveChanges : AppStrings.createExpense),
                onPressed: (_isBusy || (!_isEditing && _activeGroupId == null)) ? null : _submit,
              ),
              if (_isEditing)
                AppButton.destructive(
                  label: _isDeleting ? AppStrings.deleting : AppStrings.deleteExpense,
                  onPressed: _isBusy ? null : _delete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupFields() {
    final groupId = _activeGroupId;
    if (groupId == null) {
      return [const BodyText.medium(AppStrings.noActiveGroupMessage)];
    }

    final groupProvider = context.watch<GroupProvider>();
    if (groupProvider.isLoadingMembers(groupId)) {
      return [const Center(child: CircularProgressIndicator.adaptive())];
    }

    final members = groupProvider.membersFor(groupId);
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;

    return [
      MemberDropdownField(
        hint: AppStrings.payerLabel,
        members: members,
        value: _selectedPayer,
        currentUserId: currentUserId,
        enabled: !_isBusy,
        onChanged: (member) => setState(() => _selectedPayer = member),
      ),
      Align(alignment: Alignment.centerLeft, child: TitleText.small(AppStrings.splitsLabel)),
      for (final member in members) _buildSplitRow(member, currentUserId),
      AppButton.secondary(label: AppStrings.splitEqually, onPressed: _isBusy ? null : _splitEqually),
    ];
  }

  Widget _buildSplitRow(GroupMemberModel member, String? currentUserId) {
    final isChecked = _checkedMemberIds.contains(member.userId);
    final label = member.userId == currentUserId ? '${member.name}${AppStrings.youSuffix}' : member.name;

    return Row(
      children: [
        Checkbox(value: isChecked, onChanged: _isBusy ? null : (checked) => _toggleSplitMember(member.userId, checked ?? false)),
        Expanded(child: BodyText.medium(label)),
        if (isChecked)
          SizedBox(
            width: 100,
            child: AppTextField(
              label: AppStrings.amountOwedLabel,
              controller: _splitControllerFor(member.userId),
              enabled: !_isBusy,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
      ],
    );
  }
}
