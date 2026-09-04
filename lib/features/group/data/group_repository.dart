import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/core/services/group_service.dart';
import 'package:huddle/features/group/models/group_model.dart';

/// Read-through cache for the account's groups - pure data access (fetch remote, mirror
/// to [cache]), no scheduling/retry policy. That lives in [GroupProvider]; mirrors the
/// role [JournalRepository] plays for journal drafts.
class GroupRepository {
  GroupRepository({required this.remote, required this.cache});

  final GroupService remote;
  final JsonCache cache;

  static const _key = 'groups';

  List<GroupModel> cachedGroups() => cache.getList(_key, GroupModel.fromJson);

  Future<List<GroupModel>> syncGroups() async {
    final groups = await remote.listGroups();
    await cache.setList(_key, groups.map((group) => group.toCacheJson()).toList());
    return groups;
  }
}
