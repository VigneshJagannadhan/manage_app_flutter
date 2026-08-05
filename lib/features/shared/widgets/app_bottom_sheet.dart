import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_assets.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_svg_icon.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, this.icon, required this.title, required this.body, this.buttonLabel, this.onButtonPressed, this.footer})
    : assert(footer == null || (buttonLabel == null && onButtonPressed == null), 'Provide either buttonLabel/onButtonPressed or footer, not both');

  final IconData? icon;
  final String title;
  final Widget body;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final Widget? footer;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    IconData? icon,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
    Widget? footer,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: AppBottomSheet(icon: icon, title: title, buttonLabel: buttonLabel, onButtonPressed: onButtonPressed, footer: footer, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = context.appTheme;
    final margin = theme.horizontalMargin ?? 16;
    final verticalMargin = theme.verticalMargin ?? 16;
    final spacingSmall = theme.spacingSmall ?? 8;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(theme.appBorderRadius ?? 20)),
      child: Container(
        color: colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: spacingSmall),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 4),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(margin, verticalMargin, spacingSmall, 0),
                child: Row(
                  children: [
                    if (icon != null) ...[Icon(icon, color: colorScheme.primary), SizedBox(width: spacingSmall)],
                    Expanded(child: Text(title, style: theme.titleLarge)),
                    IconButton(icon: const AppSvgIcon(SvgIcons.close), onPressed: () => navigationService.pop(context), tooltip: AppStrings.closeTooltip),
                  ],
                ),
              ),
              Flexible(
                child: Padding(padding: EdgeInsets.fromLTRB(margin, spacingSmall, margin, verticalMargin), child: body),
              ),
              if (footer != null)
                Padding(padding: EdgeInsets.fromLTRB(margin, 0, margin, verticalMargin), child: footer)
              else if (buttonLabel != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(margin, 0, margin, verticalMargin),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(label: buttonLabel!, onPressed: onButtonPressed),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
