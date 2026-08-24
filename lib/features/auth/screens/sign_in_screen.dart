import 'package:flutter/material.dart';
import 'package:huddle/core/providers/global_data_provider.dart';
import 'package:huddle/core/resources/app_assets.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/core/themes/constants/app_sizing.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/auth/screens/sign_up_screen.dart';
import 'package:huddle/features/auth/validators/auth_validators.dart';
import 'package:huddle/features/auth/widgets/auth_footer.dart';
import 'package:huddle/features/home/screens/home_screen.dart';
import 'package:huddle/features/shared/widgets/app_body_column.dart';
import 'package:huddle/features/shared/widgets/app_button.dart';
import 'package:huddle/features/shared/widgets/app_image.dart';
import 'package:huddle/features/shared/widgets/app_scaffold.dart';
import 'package:huddle/features/shared/widgets/app_text_field.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:huddle/features/shared/widgets/text/display_text.dart';
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
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      await context.read<GlobalDataProvider>().loadAllData();
      if (!mounted) return;
      navigationService.pushAndRemoveUntil(context, HomeScreen());
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
    }
  }

  void _openSignUp() {
    navigationService.push(context, const SignUpScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthProvider>().isLoading;

    return AppScaffold(
      scrollable: true,
      body: Form(
        key: _formKey,
        child: AppBodyColumn(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage.asset(
              source: AppImages.appLogo,
              width: AppSizing.size36,
              height: AppSizing.size36,
            ),
            DisplayText.medium(
              AppStrings.welcomeBack,
              textAlign: TextAlign.center,
            ),
            BodyText.medium(
              AppStrings.signInSubtitle,
              textAlign: TextAlign.center,
            ),
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
    );
  }
}
