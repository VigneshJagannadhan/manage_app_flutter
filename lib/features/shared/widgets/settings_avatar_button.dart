import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/settings/screens/settings_screen.dart';

class SettingsAvatarButton extends StatelessWidget {
  const SettingsAvatarButton({super.key});

  void _openSettings(BuildContext context) {
    navigationService.push(context, const SettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
      ),
      tooltip: AppStrings.settings,
      onPressed: () => _openSettings(context),
    );
  }
}
