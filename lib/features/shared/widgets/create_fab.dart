import 'package:flutter/material.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';

/// Labelled extended FAB used for the primary "create" action on a tab's
/// root screen - a plain icon-only FAB reads as generic, the label makes the
/// action self-explanatory at a glance.
class CreateFab extends StatelessWidget {
  const CreateFab({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: onPressed,
      icon: const AppSvgIcon(SvgIcons.add, size: 20),
      label: Text(label),
    );
  }
}
