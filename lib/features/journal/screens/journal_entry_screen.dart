import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/journal/models/journal_entry_model.dart';
import 'package:manage_app/features/journal/providers/journal_provider.dart';
import 'package:manage_app/features/journal/widgets/journal_save_status_indicator.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:provider/provider.dart';

/// The "inner journal page" - a fully editable, borderless textfield for one calendar day.
/// No save button anywhere: edits autosave locally on a short debounce and sync to the
/// server on a coarser trigger (see [JournalProvider]); any pending sync is flushed
/// before the screen is allowed to pop, and on the app being backgrounded/killed.
class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key, required this.date, this.entry});

  final DateTime date;
  final JournalEntryModel? entry;

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> with WidgetsBindingObserver {
  late final _controller = TextEditingController(
    text: context.read<JournalProvider>().resolveInitialContent(widget.date, widget.entry?.content),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS can kill the process without ever calling dispose() - flush on backgrounding
    // too, not just on explicit navigation away, so a paused-then-killed session doesn't
    // leave the last few keystrokes unsynced.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      context.read<JournalProvider>().flushPendingSync(widget.date);
    }
  }

  void _onChanged(String value) {
    context.read<JournalProvider>().onEntryChanged(widget.date, value);
  }

  void _retry() {
    context.read<JournalProvider>().flushPendingSync(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final status = context.watch<JournalProvider>().statusFor(widget.date);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await context.read<JournalProvider>().flushPendingSync(widget.date);
        if (context.mounted) Navigator.of(context).pop();
      },
      child: AppScaffold(
        appBar: ScreenAppBar(
          title: widget.date.isToday ? AppStrings.today : widget.date.formattedShortDate,
          actions: [JournalSaveStatusIndicator(status: status, onRetry: _retry)],
        ),
        body: Padding(
          padding: EdgeInsets.all(theme.horizontalMargin ?? 16),
          child: Column(
            children: [
              Expanded(
                child: AppTextField.multiline(
                  controller: _controller,
                  hint: AppStrings.journalEntryHint,
                  onChanged: _onChanged,
                  autofocus: widget.entry == null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
