import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:huddle/core/data/pending_mutation.dart';

/// One shared store for pending offline mutations across every entity type (task now,
/// expense/journal later) - mirrors `JsonCache`'s shared-generic-class pattern rather than
/// one bespoke store per feature. Keyed by `'<entityType>:<entityId>'`, so there's at most
/// one record per entity (see `PendingMutation` for the coalescing model).
///
/// Hive-backed by default. Also supports an in-memory mode ([MutationStore.inMemory]) for
/// widget tests - real Hive box I/O (file locking) hangs specifically inside `testWidgets`
/// (a known Hive/flutter_test binding interaction, reproduced independently of this class),
/// even though the same `Hive.openBox` call completes instantly in a plain `test()`.
class MutationStore {
  MutationStore(this.boxName) : _memory = null;

  MutationStore.inMemory() : boxName = null, _memory = <String, String>{};

  final String? boxName;
  final Map<String, String>? _memory;
  Box<String>? _box;

  bool get _isInMemory => _memory != null;

  Future<void> init() async {
    if (_isInMemory) return;
    _box = await Hive.openBox<String>(boxName!);
  }

  String? _read(String key) => _isInMemory ? _memory![key] : _requireBox.get(key);

  Future<void> _write(String key, String value) async {
    if (_isInMemory) {
      _memory![key] = value;
    } else {
      await _requireBox.put(key, value);
    }
  }

  Future<void> _remove(String key) async {
    if (_isInMemory) {
      _memory!.remove(key);
    } else {
      await _requireBox.delete(key);
    }
  }

  Iterable<String> get _allKeys => _isInMemory ? _memory!.keys : _requireBox.keys.cast<String>();

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) throw StateError('MutationStore.init() must complete before use.');
    return box;
  }

  String _key(String entityType, String entityId) => '$entityType:$entityId';

  PendingMutation? get(String entityType, String entityId) {
    final raw = _read(_key(entityType, entityId));
    if (raw == null) return null;
    try {
      return PendingMutation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      unawaited(delete(entityType, entityId));
      return null;
    }
  }

  Future<void> put(PendingMutation mutation) => _write(_key(mutation.entityType, mutation.entityId), jsonEncode(mutation.toJson()));

  Future<void> delete(String entityType, String entityId) => _remove(_key(entityType, entityId));

  List<PendingMutation> allFor(String entityType) {
    final prefix = '$entityType:';
    return _allKeys
        .where((key) => key.startsWith(prefix))
        .map((key) {
          final raw = _read(key);
          if (raw == null) return null;
          try {
            return PendingMutation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            unawaited(_remove(key));
            return null;
          }
        })
        .whereType<PendingMutation>()
        .toList();
  }
}

final mutationStore = MutationStore('mutation_store');
