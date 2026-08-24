import 'package:shared_preferences/shared_preferences.dart';

/// Persists which group is "active" across app restarts. There is no server-side
/// concept of this - every group-scoped API call takes an explicit groupId, and the
/// client is solely responsible for remembering which one the user last picked.
class GroupPreferenceService {
  static const _activeGroupIdKey = 'groups_active_group_id';
  static const _tasksShowAllGroupsKey = 'groups_tasks_show_all';
  static const _expensesShowAllGroupsKey = 'groups_expenses_show_all';

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
  Future<bool> readTasksShowAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tasksShowAllGroupsKey) ?? true;
  }

  Future<void> saveTasksShowAllGroups(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tasksShowAllGroupsKey, value);
  }

  /// Defaults to `true` (show all groups) when nothing has been saved yet.
  Future<bool> readExpensesShowAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_expensesShowAllGroupsKey) ?? true;
  }

  Future<void> saveExpensesShowAllGroups(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expensesShowAllGroupsKey, value);
  }

  /// Wipes the locally-picked task group scope so the next account signed in on
  /// this device starts from "all groups" again.
  Future<void> clearTasksShowAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksShowAllGroupsKey);
  }

  /// Wipes the locally-picked expense group scope so the next account signed in
  /// on this device starts from "all groups" again.
  Future<void> clearExpensesShowAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expensesShowAllGroupsKey);
  }
}

final groupPreferenceService = GroupPreferenceService();
