import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/core/themes/constants/app_sizing.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/validators/auth_validators.dart';
import 'package:manage_app/features/auth/widgets/auth_footer.dart';
import 'package:manage_app/features/home/screens/home_screen.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_image.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:manage_app/features/shared/widgets/text/display_text.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fullNameRequired;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.confirmPasswordRequired;
    if (value != _passwordController.text) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      navigationService.pushAndRemoveUntil(context, HomeScreen());
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
    }
  }

  void _backToSignIn() {
    navigationService.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthProvider>().isLoading;

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formKey,
              child: AppBodyColumn(
                spacing: 16,
                children: [
                  AppImage.asset(source: AppImages.appLogo, width: AppSizing.size36, height: AppSizing.size36),
                  DisplayText.medium(AppStrings.createAccount, textAlign: TextAlign.center),
                  BodyText.medium(AppStrings.signUpSubtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: AppStrings.fullNameLabel,
                    controller: _fullNameController,
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    enabled: !isSubmitting,
                    validator: _validateFullName,
                  ),
                  AppTextField(
                    label: AppStrings.emailLabel,
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !isSubmitting,
                    validator: validateEmail,
                  ),
                  AppTextField.password(
                    label: AppStrings.passwordLabel,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    enabled: !isSubmitting,
                    validator: validatePassword,
                  ),
                  AppTextField.password(
                    label: AppStrings.confirmPasswordLabel,
                    controller: _confirmPasswordController,
                    textInputAction: TextInputAction.done,
                    enabled: !isSubmitting,
                    validator: _validateConfirmPassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  AppButton.primary(
                    label: isSubmitting ? AppStrings.creatingAccount : AppStrings.signUp,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                  AuthFooter(
                    promptText: AppStrings.alreadyHaveAccount,
                    actionText: AppStrings.signIn,
                    onPressed: isSubmitting ? null : _backToSignIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
