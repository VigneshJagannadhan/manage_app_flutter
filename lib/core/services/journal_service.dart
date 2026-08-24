import 'package:huddle/core/constants/app_urls.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/services/api_result.dart';
import 'package:huddle/core/services/api_services.dart';
import 'package:huddle/features/journal/models/journal_entry_model.dart';

class JournalServiceException implements Exception {
  JournalServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JournalService {
  JournalService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  /// Entries whose calendar day falls within the closed range [from, to]. Any day in that
  /// range with no matching entry in the result is a "missing" day - the caller (see
  /// [JournalProvider]) fills those gaps itself rather than the server returning placeholders.
  Future<List<JournalEntryModel>> listEntries({required DateTime from, required DateTime to}) async {
    final result = await _api.get<List<JournalEntryModel>>(
      AppUrls.journals,
      queryParameters: {'from': from.toServer(), 'to': to.toServer()},
      parser: (data) => (data as List<dynamic>).map((entry) => JournalEntryModel.fromJson(entry as Map<String, dynamic>)).toList(),
    );
    return _unwrap(result);
  }

  /// Creates the entry for [date] if none exists yet, otherwise updates its content - the same
  /// call backs the first write of the day, every autosave, and backfilling a past missing day.
  Future<JournalEntryModel> upsertEntry({required DateTime date, required String content}) async {
    final result = await _api.put<JournalEntryModel>(
      AppUrls.journals,
      data: {'date': date.atMidnight.toServer(), 'content': content},
      parser: (data) => JournalEntryModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw JournalServiceException(failure.message));
  }
}

final journalService = JournalService();
