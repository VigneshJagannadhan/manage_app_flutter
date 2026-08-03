import 'package:shared_preferences/shared_preferences.dart';

/// Persists which group is "active" across app restarts. There is no server-side
/// concept of this - every group-scoped API call takes an explicit groupId, and the
/// client is solely responsible for remembering which one the user last picked.
class GroupPreferenceService {
  static const _activeGroupIdKey = 'groups_active_group_id';

  Future<String?> readActiveGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeGroupIdKey);
  }

  Future<void> saveActiveGroupId(String? groupId) async {
    final prefs = await SharedPreferences.getInstance();
    if (groupId == null) {
      await prefs.remove(_activeGroupIdKey);
    } else {
      await prefs.setString(_activeGroupIdKey, groupId);
    }
  }
}

final groupPreferenceService = GroupPreferenceService();
