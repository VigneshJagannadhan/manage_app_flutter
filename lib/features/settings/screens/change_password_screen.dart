import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/validators/auth_validators.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty)
      return AppStrings.currentPasswordRequired;
    return null;
  }

  String? _validateConfirmNewPassword(String? value) {
    if (value == null || value.isEmpty)
      return AppStrings.confirmPasswordRequired;
    if (value != _newPasswordController.text)
      return AppStrings.passwordsDoNotMatch;
    return null;
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final profileProvider = context.read<ProfileProvider>();
    final success = await profileProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '${AppStrings.passwordChanged}. ${AppStrings.passwordChangedNote}',
          ),
        ),
      );
      navigationService.pop(context);
    } else if (profileProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(profileProvider.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChangingPassword = context
        .watch<ProfileProvider>()
        .isChangingPassword;

    return AppScaffold(
      appBar: const ScreenAppBar(title: AppStrings.changePassword),
      scrollable: true,
      body: Form(
        key: _formKey,
        child: AppBodyColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            AppTextField.password(
              label: AppStrings.currentPasswordLabel,
              controller: _currentPasswordController,
              textInputAction: TextInputAction.next,
              enabled: !isChangingPassword,
              validator: _validateCurrentPassword,
            ),
            AppTextField.password(
              label: AppStrings.newPasswordLabel,
              controller: _newPasswordController,
              textInputAction: TextInputAction.next,
              enabled: !isChangingPassword,
              validator: validatePassword,
            ),
            AppTextField.password(
              label: AppStrings.confirmNewPasswordLabel,
              controller: _confirmNewPasswordController,
              textInputAction: TextInputAction.done,
              enabled: !isChangingPassword,
              validator: _validateConfirmNewPassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            AppButton.primary(
              label: isChangingPassword
                  ? AppStrings.changingPassword
                  : AppStrings.changePassword,
              onPressed: isChangingPassword ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
