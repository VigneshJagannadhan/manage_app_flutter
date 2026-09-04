import 'package:shared_preferences/shared_preferences.dart';

/// Persists which group is "active" across app restarts. There is no server-side
/// concept of this - every group-scoped API call takes an explicit groupId, and the
/// client is solely responsible for remembering which one the user last picked.
class GroupPreferenceService {
  static const _activeGroupIdKey = 'groups_active_group_id';
  static const _showAllGroupsKey = 'groups_show_all';

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

  /// Defaults to `true` (show all groups) when nothing has been saved yet.
  Future<bool> readShowAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showAllGroupsKey) ?? true;
  }

  Future<void> saveShowAllGroups(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAllGroupsKey, value);
  }

  /// Wipes the locally-picked group scope so the next account signed in on
  /// this device starts from "all groups" again.
  Future<void> clearShowAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_showAllGroupsKey);
  }
}

final groupPreferenceService = GroupPreferenceService();
