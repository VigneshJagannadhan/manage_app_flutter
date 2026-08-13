import 'package:flutter/material.dart';
import 'package:manage_app/core/enums/group_enums.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/group_service.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/group/models/group_model.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/group/widgets/invite_code_view.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/text/label_text.dart';
import 'package:provider/provider.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key, required this.group});

  final GroupModel group;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late GroupModel _group = widget.group;
  late final _nameController = TextEditingController(text: _group.name);
  bool _isRenaming = false;
  bool _isDeleting = false;

  bool get _isOwner => _group.role == GroupRole.owner;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final newName = _nameController.text.trim();
    if (newName == _group.name) return;

    setState(() => _isRenaming = true);
    try {
      final updated = await context.read<GroupProvider>().renameGroup(_group.id, newName);
      if (!mounted) return;
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.groupRenamed)));
    } on GroupServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isRenaming = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteGroup),
        content: const Text(AppStrings.deleteGroupConfirmation),
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
      await context.read<GroupProvider>().deleteGroup(_group.id);
      if (!mounted) return;
      navigationService.pop(context);
    } on GroupServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(title: _group.name),
      scrollable: true,
      body: AppBodyColumn(
        spacing: 16,
        children: [
          InviteCodeView(group: _group),
          if (_isOwner) ..._buildOwnerSections(),
        ],
      ),
    );
  }

  List<Widget> _buildOwnerSections() {
    return [
      Form(
        key: _formKey,
        child: AppBodyColumn(
          padding: EdgeInsets.zero,
          spacing: 16,
          children: [
            AppTextField(
              label: AppStrings.groupNameLabel,
              controller: _nameController,
              enabled: !_isRenaming,
              validator: (value) => (value == null || value.trim().isEmpty) ? AppStrings.groupNameRequired : null,
            ),
            AppButton.primary(
              label: _isRenaming ? AppStrings.saving : AppStrings.saveChanges,
              onPressed: _isRenaming ? null : _rename,
            ),
          ],
        ),
      ),
      AppButton.destructive(
        label: _isDeleting ? AppStrings.deleting : AppStrings.deleteGroup,
        onPressed: _isDeleting ? null : _delete,
      ),
    ];
  }
}
