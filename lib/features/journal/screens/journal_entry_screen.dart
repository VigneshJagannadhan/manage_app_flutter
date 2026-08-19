import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/journal_service.dart';
import 'package:manage_app/features/journal/models/journal_entry_model.dart';
import 'package:manage_app/features/journal/providers/journal_provider.dart';
import 'package:manage_app/features/journal/widgets/journal_save_status_indicator.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/app_text_field.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:provider/provider.dart';

/// The "inner journal page" - a fully editable, borderless textfield for one calendar day.
/// No save button anywhere: edits autosave on a debounce, and any pending edit is flushed
/// before the screen is allowed to pop.
class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key, required this.date, this.entry});

  final DateTime date;
  final JournalEntryModel? entry;

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  static const _autosaveDebounce = Duration(milliseconds: 800);

  late final _controller = TextEditingController(text: widget.entry?.content ?? '');
  late String _lastSavedContent = _controller.text;
  Timer? _debounce;
  JournalSaveStatus _status = JournalSaveStatus.idle;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_autosaveDebounce, _save);
  }

  Future<void> _save() async {
    final content = _controller.text;
    if (content == _lastSavedContent) return;

    setState(() => _status = JournalSaveStatus.saving);
    try {
      await context.read<JournalProvider>().upsertEntry(date: widget.date, content: content);
      _lastSavedContent = content;
      if (!mounted) return;
      setState(() => _status = JournalSaveStatus.saved);
    } on JournalServiceException {
      if (!mounted) return;
      setState(() => _status = JournalSaveStatus.error);
    }
  }

  /// Flushes a pending debounced edit (if any) before the pop is allowed to complete, so
  /// the last few keystrokes before a quick exit aren't lost.
  Future<void> _flushPendingSave() async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _flushPendingSave();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: AppScaffold(
        appBar: ScreenAppBar(
          title: widget.date.isToday ? AppStrings.today : widget.date.formattedShortDate,
          actions: [JournalSaveStatusIndicator(status: _status, onRetry: _save)],
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
