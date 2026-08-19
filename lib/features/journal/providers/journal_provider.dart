import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/services/journal_service.dart';
import 'package:manage_app/features/journal/models/journal_entry_model.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

/// One day in the journal feed - either backed by an [entry], or `null` for a day the
/// user never wrote anything for.
class JournalDaySlot {
  const JournalDaySlot({required this.date, this.entry});

  final DateTime date;
  final JournalEntryModel? entry;

  bool get isMissing => entry == null;
}

class JournalProvider extends BaseProvider {
  JournalProvider({required this.journalService, required this.profileProvider});

  final JournalService journalService;
  final ProfileProvider profileProvider;

  /// Days fetched per page, oldest-first from today - bounds how far back a single
  /// request reaches so the whole account history is never fetched in one call.
  static const _windowSizeInDays = 30;

  @override
  void onInit() {}

  @override
  void onDispose() {
    clearEntries();
  }

  final Map<DateTime, JournalEntryModel> _entriesByDate = {};

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

  /// Creates the entry for [date] if none exists yet, otherwise updates its content.
  /// Used for the first write of the day, every autosave, and backfilling a past day.
  Future<JournalEntryModel> upsertEntry({required DateTime date, required String content}) async {
    final result = await journalService.upsertEntry(date: date, content: content);
    _entriesByDate[result.date] = result;
    notifyListeners();
    return result;
  }

  void clearEntries() {
    _entriesByDate.clear();
    _earliestLoadedDate = null;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// [to] minus [_windowSizeInDays], clamped so the range never reaches earlier than
  /// the account's creation date.
  DateTime _clampedFrom(DateTime to) {
    final candidate = _daysBefore(to, _windowSizeInDays - 1);
    return candidate.isBefore(_accountCreatedDate) ? _accountCreatedDate : candidate;
  }

  void _mergeEntries(List<JournalEntryModel> entries) {
    for (final entry in entries) {
      _entriesByDate[entry.date] = entry;
    }
  }

  /// Steps back [days] calendar days from [date] via the date components rather than
  /// `Duration` subtraction, so a DST transition can't shift the result off midnight.
  DateTime _daysBefore(DateTime date, int days) => DateTime(date.year, date.month, date.day - days);
}
