import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/group_service.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:provider/provider.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    setState(() => _isSubmitting = true);
    try {
      final group = await context.read<GroupProvider>().joinGroup(
        _codeController.text.trim(),
      );
      if (!mounted) return;
      navigationService.pop(context, group);
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
    return AppScaffold(
      appBar: ScreenAppBar(title: AppStrings.joinGroup),
      scrollable: true,
      body: Form(
        key: _formKey,
        child: AppBodyColumn(
          spacing: 16,
          children: [
            AppTextField(
              label: AppStrings.inviteCodeLabel,
              controller: _codeController,
              enabled: !_isSubmitting,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppStrings.inviteCodeRequired
                  : null,
            ),
            AppButton.primary(
              label: _isSubmitting ? AppStrings.joining : AppStrings.join,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
