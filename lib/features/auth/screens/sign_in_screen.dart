import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/auth/screens/sign_up_screen.dart';
import 'package:manage_app/features/auth/validators/auth_validators.dart';
import 'package:manage_app/features/auth/widgets/auth_footer.dart';
import 'package:manage_app/features/home/screens/home_screen.dart';
import 'package:manage_app/features/shared/widgets/app_body_column.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(email: _emailController.text.trim(), password: _passwordController.text);
    if (!mounted) return;

    if (success) {
      navigationService.pushAndRemoveUntil(context, HomeScreen());
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
    }
  }

  void _openSignUp() {
    navigationService.push(context, const SignUpScreen());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  Text(AppStrings.appName, style: textTheme.titleMedium?.copyWith(color: context.appTheme.primaryColor)),
                  Text(AppStrings.welcomeBack, style: textTheme.headlineSmall, textAlign: TextAlign.center),
                  Text(AppStrings.signInSubtitle, style: textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
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
                    textInputAction: TextInputAction.done,
                    enabled: !isSubmitting,
                    validator: validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  AppButton.primary(
                    label: isSubmitting ? AppStrings.signingIn : AppStrings.signIn,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                  AuthFooter(
                    promptText: AppStrings.dontHaveAccount,
                    actionText: AppStrings.signUp,
                    onPressed: isSubmitting ? null : _openSignUp,
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
