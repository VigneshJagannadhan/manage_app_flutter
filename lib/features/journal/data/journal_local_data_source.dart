import 'package:hive/hive.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';

/// A locally-cached draft for one calendar day - `dirty` means it hasn't been
/// confirmed synced to the server yet.
class JournalDraft {
  const JournalDraft({required this.content, required this.dirty, required this.updatedAt});

  final String content;
  final bool dirty;
  final DateTime updatedAt;
}

/// Hive-backed write-ahead cache for journal drafts, keyed by calendar day. Values are
/// stored as plain maps (no `@HiveType`/`TypeAdapter` codegen) - see the plan doc for why
/// this is the pattern to reuse for other features' offline caches too, not a shortcut.
class JournalLocalDataSource {
  JournalLocalDataSource({this.boxName = 'journal_drafts'});

  final String boxName;
  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Box<Map> get _requireBox {
    final box = _box;
    if (box == null) throw StateError('JournalLocalDataSource.init() must complete before use.');
    return box;
  }

  Future<void> saveDraft(DateTime date, String content) => _requireBox.put(_key(date), {
    'content': content,
    'dirty': true,
    'updatedAt': DateTime.now().toIso8601String(),
  });

  JournalDraft? getDraft(DateTime date) {
    final raw = _requireBox.get(_key(date));
    if (raw == null) return null;
    return JournalDraft(
      content: raw['content'] as String,
      dirty: raw['dirty'] as bool,
      updatedAt: DateTime.parse(raw['updatedAt'] as String),
    );
  }

  Future<void> markSynced(DateTime date) async {
    final raw = _requireBox.get(_key(date));
    if (raw == null) return;
    await _requireBox.put(_key(date), {...raw, 'dirty': false});
  }

  List<DateTime> dirtyDates() {
    return _requireBox.keys.cast<String>().where((key) {
      final raw = _requireBox.get(key);
      return raw != null && raw['dirty'] == true;
    }).map(_dateFromKey).toList();
  }

  /// Wipes every local draft - call on sign-out so a shared device doesn't leak the
  /// previous account's unsynced text into the next signed-in user's editor.
  Future<void> clearAll() => _requireBox.clear();

  String _key(DateTime date) => date.atMidnight.toIso8601String();

  DateTime _dateFromKey(String key) => DateTime.parse(key);
}

final journalLocalDataSource = JournalLocalDataSource();
