import 'package:flutter/material.dart';
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
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  GroupModel? _createdGroup;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    setState(() => _isSubmitting = true);
    try {
      final group = await context.read<GroupProvider>().createGroup(
        _nameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _createdGroup = group);
    } on GroupServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _createdGroup;
    return AppScaffold(
      appBar: ScreenAppBar(
        title: group != null ? AppStrings.groupCreated : AppStrings.createGroup,
      ),
      scrollable: true,
      body: group != null ? _buildResult(group) : _buildForm(),
    );
  }

  Widget _buildResult(GroupModel group) {
    return AppBodyColumn(
      spacing: 16,
      children: [
        InviteCodeView(group: group),
        AppButton.primary(
          label: AppStrings.done,
          onPressed: () => navigationService.pop(context, group),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AppBodyColumn(
        spacing: 16,
        children: [
          AppTextField(
            label: AppStrings.groupNameLabel,
            controller: _nameController,
            enabled: !_isSubmitting,
            autofocus: true,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? AppStrings.groupNameRequired
                : null,
          ),
          AppButton.primary(
            label: _isSubmitting ? AppStrings.creating : AppStrings.createGroup,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
