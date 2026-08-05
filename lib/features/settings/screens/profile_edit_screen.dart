import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/validators/auth_validators.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/settings/screens/change_password_screen.dart';
import 'package:manage_app/features/settings/validators/profile_validators.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:provider/provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: context.read<ProfileProvider>().profile?.name);
  late final _emailController = TextEditingController(text: context.read<ProfileProvider>().profile?.email);
  late final _phoneController = TextEditingController(text: context.read<ProfileProvider>().profile?.phone);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fullNameRequired;
    return null;
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final profileProvider = context.read<ProfileProvider>();
    final phone = _phoneController.text.trim();
    final updated = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: phone.isEmpty ? null : phone,
    );
    if (!mounted) return;

    if (updated != null) {
      await context.read<AuthProvider>().updateCurrentUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.profileUpdated)));
      navigationService.pop(context);
    } else if (profileProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(profileProvider.errorMessage!)));
    }
  }

  void _openChangePassword() {
    navigationService.push(context, const ChangePasswordScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ProfileProvider>().isSaving;
    final theme = context.appTheme;

    return AppScaffold(
      appBar: const ScreenAppBar(title: AppStrings.editProfile),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AppBodyColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              AppTextField(
                label: AppStrings.fullNameLabel,
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                enabled: !isSaving,
                validator: _validateName,
              ),
              AppTextField(
                label: AppStrings.emailLabel,
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isSaving,
                validator: validateEmail,
              ),
              AppTextField(
                label: AppStrings.phoneLabel,
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                enabled: !isSaving,
                validator: validatePhone,
              ),
              Text(AppStrings.passwordLabel, style: theme.labelLarge),
              Text('••••••••', style: theme.bodyLarge),
              AppButton.secondary(label: AppStrings.changePassword, onPressed: isSaving ? null : _openChangePassword),
              AppButton.primary(
                label: isSaving ? AppStrings.updating : AppStrings.updateProfile,
                onPressed: isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
