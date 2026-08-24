import 'dart:async';

import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/services/connectivity_service.dart';
import 'package:huddle/core/services/journal_service.dart';
import 'package:huddle/features/journal/data/journal_repository.dart';
import 'package:huddle/features/journal/models/journal_entry_model.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

/// One day in the journal feed - either backed by an [entry], or `null` for a day the
/// user never wrote anything for.
class JournalDaySlot {
  const JournalDaySlot({required this.date, this.entry});

  final DateTime date;
  final JournalEntryModel? entry;

  bool get isMissing => entry == null;
}

/// `savedLocally` renders the same as `idle` in the UI - the draft is safe on-device, and
/// surfacing that distinction to the user would be noise beyond what's useful; only the
/// states that matter for trusting the server sync (`syncing`/`synced`/`error`) render
/// anything (see [JournalSaveStatusIndicator]).
enum JournalSyncStatus { idle, savedLocally, syncing, synced, error }

class JournalProvider extends BaseProvider {
  JournalProvider({
    required this.journalService,
    required this.repository,
    required this.connectivityService,
    required this.profileProvider,
  });

  final JournalService journalService;
  final JournalRepository repository;
  final ConnectivityService connectivityService;
  final ProfileProvider profileProvider;

  /// Fast write-ahead tier: how long to wait after the last keystroke before the draft
  /// is written to local storage (no network involved - cheap, so this stays short).
  static const _localSaveDebounce = Duration(milliseconds: 800);

  /// Sync tier, idle branch: how long the user has to stop typing before the draft is
  /// pushed to the server.
  static const _idleSyncTimeout = Duration(seconds: 5);

  /// Sync tier, ceiling branch: forces a sync even during continuous typing, so a
  /// non-stop typing session still checkpoints to the server periodically instead of
  /// going unsynced until the user finally pauses. Measured since the last sync, not
  /// since the first keystroke of the streak.
  static const _maxWaitCeiling = Duration(seconds: 20);

  @override
  void onInit() {
    // Catches any drafts left dirty by a previous session (e.g. the app was killed
    // before a pending sync completed).
    _syncAllDirty();
    _connectivitySub = connectivityService.onConnectivityChanged.listen((connected) {
      if (connected) _syncAllDirty();
    });
  }

  @override
  void onDispose() {
    clearEntries();
    _connectivitySub?.cancel();
  }

  StreamSubscription<bool>? _connectivitySub;

  final Map<DateTime, JournalEntryModel> _entriesByDate = {};

  /// Latest in-editor content per date, kept so a timer firing later always acts on the
  /// most recent keystrokes rather than whatever was current when it was scheduled.
  final Map<DateTime, String> _pendingContent = {};
  final Map<DateTime, JournalSyncStatus> _statusByDate = {};
  final Map<DateTime, Timer> _localTimers = {};
  final Map<DateTime, Timer> _idleTimers = {};
  final Map<DateTime, Timer> _maxWaitTimers = {};

  JournalSyncStatus statusFor(DateTime date) => _statusByDate[date] ?? JournalSyncStatus.idle;

  // Inclusive lower bound of what's been fetched so far; `null` means [loadInitial] hasn't run yet.
  DateTime? _earliestLoadedDate;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime get _today => DateTime.now().atMidnight;

  // Falls back to today when the profile hasn't loaded `createdAt` yet (or the backend
  // response predates that field) - degrades to a today-only feed rather than generating
  // "missing" days all the way back to the epoch.
  DateTime get _accountCreatedDate => (profileProvider.profile?.createdAt ?? _today).atMidnight;

  /// Today back to the earliest loaded date, descending, each paired with its entry or
  /// `null` for a missing day. Empty until [loadInitial] has completed.
  List<JournalDaySlot> get days {
    final earliest = _earliestLoadedDate;
    if (earliest == null) return const [];
    final slots = <JournalDaySlot>[];
    for (var date = _today; !date.isBefore(earliest); date = _daysBefore(date, 1)) {
      slots.add(JournalDaySlot(date: date, entry: _entriesByDate[date]));
    }
    return slots;
  }

  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final to = _today;
      final from = _clampedFrom(to);
      _mergeEntries(await journalService.listEntries(from: from, to: to));
      _earliestLoadedDate = from;
      _hasMore = from.isAfter(_accountCreatedDate);
    } on JournalServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final earliest = _earliestLoadedDate;
    if (earliest == null || !_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();
    try {
      final to = _daysBefore(earliest, 1);
      final from = _clampedFrom(to);
      _mergeEntries(await journalService.listEntries(from: from, to: to));
      _earliestLoadedDate = from;
      _hasMore = from.isAfter(_accountCreatedDate);
    } on JournalServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// The text a [JournalEntryScreen] for [date] should open with - a dirty local draft
  /// (an edit that reached local storage but hasn't synced to the server yet) wins over
  /// whatever the caller already fetched from the server.
  String resolveInitialContent(DateTime date, String? remoteContent) =>
      repository.contentForDate(date, remoteFallback: remoteContent);

  /// Called on every keystroke. Resets the local-save debounce and the idle-sync timer;
  /// starts the max-wait ceiling only if one isn't already running for this date, so a
  /// continuous typing streak still checkpoints to the server periodically.
  void onEntryChanged(DateTime date, String content) {
    _pendingContent[date] = content;

    _localTimers[date]?.cancel();
    _localTimers[date] = Timer(_localSaveDebounce, () => _saveLocal(date));

    _idleTimers[date]?.cancel();
    _idleTimers[date] = Timer(_idleSyncTimeout, () => _syncNow(date));

    _maxWaitTimers.putIfAbsent(date, () => Timer(_maxWaitCeiling, () => _syncNow(date)));
  }

  /// Cancels any pending timers for [date] and forces both tiers immediately - used when
  /// the editor is about to go away (back-navigation, app backgrounded/killed) so the
  /// last few keystrokes before a quick exit aren't left unsynced.
  Future<void> flushPendingSync(DateTime date) => _syncNow(date);

  Future<void> _saveLocal(DateTime date) async {
    final content = _pendingContent[date];
    if (content == null) return;
    try {
      await repository.saveDraftLocally(date, content);
      _statusByDate[date] = JournalSyncStatus.savedLocally;
      notifyListeners();
    } catch (_) {
      // A local-storage hiccup, not a network error - leave status as-is and let the
      // next debounce tick (or the sync tier, which re-persists before syncing) retry.
    }
  }

  Future<void> _syncNow(DateTime date) async {
    _localTimers.remove(date)?.cancel();
    _idleTimers.remove(date)?.cancel();
    _maxWaitTimers.remove(date)?.cancel();

    // Guards against connectivity-regained and a timer firing for the same date near-
    // simultaneously, which would otherwise fire two concurrent PUTs.
    if (_statusByDate[date] == JournalSyncStatus.syncing) return;

    final content = _pendingContent[date];
    if (content != null) {
      try {
        await repository.saveDraftLocally(date, content);
      } catch (_) {
        // Same as _saveLocal - a storage hiccup shouldn't block attempting the sync
        // below against whatever was last successfully persisted.
      }
    }

    _statusByDate[date] = JournalSyncStatus.syncing;
    notifyListeners();
    try {
      final result = await repository.syncEntry(date);
      if (result != null) _entriesByDate[result.date] = result;
      _pendingContent.remove(date);
      _statusByDate[date] = JournalSyncStatus.synced;
    } on JournalServiceException {
      _statusByDate[date] = JournalSyncStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _syncAllDirty() async {
    for (final date in repository.dirtyDates()) {
      await _syncNow(date);
    }
  }

  void clearEntries() {
    _entriesByDate.clear();
    _earliestLoadedDate = null;
    _hasMore = true;
    _errorMessage = null;

    _pendingContent.clear();
    _statusByDate.clear();
    for (final timer in _localTimers.values) {
      timer.cancel();
    }
    _localTimers.clear();
    for (final timer in _idleTimers.values) {
      timer.cancel();
    }
    _idleTimers.clear();
    for (final timer in _maxWaitTimers.values) {
      timer.cancel();
    }
    _maxWaitTimers.clear();
    // Not awaited - clearEntries() is called synchronously from sign-out and shouldn't
    // block on I/O; a shared device switching accounts is the scenario this guards
    // against, and clearing is fire-and-forget-safe since nothing reads the box until
    // the next entry screen opens or the next sync tick.
    unawaited(repository.clearLocalDrafts());

    notifyListeners();
  }

  /// [to] minus [_windowSizeInDays], clamped so the range never reaches earlier than
  /// the account's creation date.
  DateTime _clampedFrom(DateTime to) {
    final candidate = _daysBefore(to, _windowSizeInDays - 1);
    return candidate.isBefore(_accountCreatedDate) ? _accountCreatedDate : candidate;
  }

  /// Days fetched per page, oldest-first from today - bounds how far back a single
  /// request reaches so the whole account history is never fetched in one call.
  static const _windowSizeInDays = 30;

  void _mergeEntries(List<JournalEntryModel> entries) {
    for (final entry in entries) {
      _entriesByDate[entry.date] = entry;
    }
  }

  /// Steps back [days] calendar days from [date] via the date components rather than
  /// `Duration` subtraction, so a DST transition can't shift the result off midnight.
  DateTime _daysBefore(DateTime date, int days) => DateTime(date.year, date.month, date.day - days);
}
