import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/providers/notification_schedule_provider.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/local_notification_service.dart';
import 'package:huddle/features/settings/providers/notification_preferences_provider.dart';
import 'package:huddle/features/settings/services/notification_preferences_service.dart';
import 'package:huddle/features/shared/widgets/app_body_column.dart';
import 'package:huddle/features/shared/widgets/app_scaffold.dart';
import 'package:huddle/features/shared/widgets/screen_appbar.dart';
import 'package:huddle/features/shared/widgets/text/body_text.dart';
import 'package:provider/provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          NotificationPreferencesProvider(
              notificationPreferencesService: notificationPreferencesService,
              notificationScheduleProvider: context.read<NotificationScheduleProvider>(),
              localNotificationService: localNotificationService,
            )
            ..onInit()
            ..loadPreferences(),
      child: AppScaffold(
        appBar: const ScreenAppBar(title: AppStrings.notifications),
        scrollable: true,
        body: const _NotificationPreferencesBody(),
      ),
    );
  }
}

class _NotificationPreferencesBody extends StatelessWidget {
  const _NotificationPreferencesBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationPreferencesProvider>();
    final preferences = provider.preferences;

    if (provider.isLoading && preferences == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (preferences == null) {
      return Center(child: BodyText.medium(provider.errorMessage ?? AppStrings.couldNotLoadNotificationPreferences));
    }

    final theme = context.appTheme;
    return AppBodyColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacingMedium,
      children: [
        _ReminderToggleRow(
          label: AppStrings.generalReminders,
          enabled: preferences.generalRemindersEnabled,
          onChanged: provider.setGeneralRemindersEnabled,
        ),
        BodyText.small(AppStrings.generalRemindersNoFixedTime, color: Theme.of(context).colorScheme.onSurfaceVariant),

        _ReminderToggleRow(
          label: AppStrings.journalReminders,
          enabled: preferences.journalReminderEnabled,
          onChanged: provider.setJournalReminderEnabled,
        ),
        if (preferences.journalReminderEnabled)
          _ReminderTimeRow(time: preferences.journalReminderTime, onChanged: provider.setJournalReminderTime),

        _ReminderToggleRow(
          label: AppStrings.taskReminders,
          enabled: preferences.taskReminderEnabled,
          onChanged: provider.setTaskReminderEnabled,
        ),
        BodyText.small(AppStrings.taskRemindersNoFixedTime, color: Theme.of(context).colorScheme.onSurfaceVariant),

        _ReminderToggleRow(
          label: AppStrings.expenseReminders,
          enabled: preferences.expenseRemindersEnabled,
          onChanged: provider.setExpenseRemindersEnabled,
        ),
        if (preferences.expenseRemindersEnabled)
          _ReminderTimeRow(time: preferences.expenseReminderTime, onChanged: provider.setExpenseReminderTime),
      ],
    );
  }
}

class _ReminderToggleRow extends StatelessWidget {
  const _ReminderToggleRow({required this.label, required this.enabled, required this.onChanged});

  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: enabled,
      label: label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [BodyText.medium(label), Switch.adaptive(value: enabled, onChanged: onChanged)],
      ),
    );
  }
}

class _ReminderTimeRow extends StatelessWidget {
  const _ReminderTimeRow({required this.time, required this.onChanged});

  final String? time;
  final ValueChanged<String> onChanged;

  Future<void> _pickTime(BuildContext context) async {
    final initial = _parseTime(time) ?? const TimeOfDay(hour: 20, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(theme.appBorderRadius),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacingXSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BodyText.small(AppStrings.reminderTime, color: Theme.of(context).colorScheme.onSurfaceVariant),
            BodyText.medium(time ?? '--:--'),
          ],
        ),
      ),
    );
  }
}
