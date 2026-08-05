import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';

/// "`promptText` `actionText`" row used under sign-in/sign-up forms to
/// switch between the two screens.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, required this.promptText, required this.actionText, required this.onPressed});

  final String promptText;
  final String actionText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(promptText, style: context.appTheme.bodyMedium),
        TextButton(onPressed: onPressed, child: Text(actionText)),
      ],
    );
  }
}
