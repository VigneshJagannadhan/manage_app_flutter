import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';

/// One shared Hive-backed cache for whole-object/whole-list domain data (profile, groups,
/// tasks, expenses, ...), keyed by a simple string per feature. Values are stored as
/// JSON-encoded strings rather than raw `Map`s (unlike [JournalLocalDataSource]'s
/// per-day `Box<Map>`) since each entry here is a single blob (one object or one list),
/// not many small per-key records - a single generic class covers all four features
/// instead of one bespoke local-data-source class per feature.
class JsonCache {
  JsonCache(this.boxName);

  final String boxName;
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) throw StateError('JsonCache.init() must complete before use.');
    return box;
  }

  /// Returns `null` on a missing OR unreadable entry - a corrupt/stale-shape cache entry
  /// must not crash the fast cache-priming path splash relies on to navigate quickly.
  T? get<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _requireBox.get(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      unawaited(clear(key));
      return null;
    }
  }

  /// Returns `[]` on a missing OR unreadable entry - see [get].
  List<T> getList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _requireBox.get(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      unawaited(clear(key));
      return [];
    }
  }

  Future<void> set(String key, Map<String, dynamic> json) => _requireBox.put(key, jsonEncode(json));

  Future<void> setList(String key, List<Map<String, dynamic>> jsonList) => _requireBox.put(key, jsonEncode(jsonList));

  Future<void> clear(String key) => _requireBox.delete(key);

  Future<void> clearAll() => _requireBox.clear();
}

final appDataCache = JsonCache('app_data_cache');
