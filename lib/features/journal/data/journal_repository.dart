import 'package:manage_app/core/services/journal_service.dart';
import 'package:manage_app/features/journal/data/journal_local_data_source.dart';
import 'package:manage_app/features/journal/models/journal_entry_model.dart';

/// Sits between [JournalProvider] and the two data sources - pure data-access
/// operations only, no timers/scheduling policy (that lives in the provider).
class JournalRepository {
  JournalRepository({required this.local, required this.remote});

  final JournalLocalDataSource local;
  final JournalService remote;

  Future<void> saveDraftLocally(DateTime date, String content) => local.saveDraft(date, content);

  /// Pushes a dirty local draft to the server; leaves it dirty on failure so the next
  /// sync attempt (timer or reconnect) retries it. Propagates [JournalServiceException]
  /// unchanged - the same type the rest of the app already catches from [JournalService].
  /// Returns `null` when there was no dirty draft to push (already in sync).
  Future<JournalEntryModel?> syncEntry(DateTime date) async {
    final draft = local.getDraft(date);
    if (draft == null || !draft.dirty) return null;
    final result = await remote.upsertEntry(date: date, content: draft.content);
    await local.markSynced(date);
    return result;
  }

  /// A dirty local draft wins over the already-fetched remote value - covers reopening a
  /// day whose last edit synced to local storage but not yet to the server.
  String contentForDate(DateTime date, {String? remoteFallback}) {
    final draft = local.getDraft(date);
    if (draft != null && draft.dirty) return draft.content;
    return remoteFallback ?? '';
  }

  List<DateTime> dirtyDates() => local.dirtyDates();

  Future<void> clearLocalDrafts() => local.clearAll();
}
