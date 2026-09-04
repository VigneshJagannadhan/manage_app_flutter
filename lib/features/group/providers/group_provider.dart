import 'dart:async';

import 'package:huddle/core/services/group_preference_service.dart';
import 'package:huddle/core/services/group_service.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/group/data/group_repository.dart';
import 'package:huddle/features/group/models/group_member_model.dart';
import 'package:huddle/features/group/models/group_model.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/settings/services/profile_service.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

class GroupProvider extends BaseProvider {
  GroupProvider({
    required this.groupService,
    required this.groupRepository,
    required this.groupPreferenceService,
    required this.authProvider,
    required this.profileProvider,
  });

  final GroupService groupService;
  final GroupRepository groupRepository;
  final GroupPreferenceService groupPreferenceService;
  final AuthProvider authProvider;
  final ProfileProvider profileProvider;

  bool _wasAuthenticated = false;

  @override
  void onInit() {
    _wasAuthenticated = authProvider.isAuthenticated;
    authProvider.addListener(_onAuthChanged);
  }

  @override
  void onDispose() {
    authProvider.removeListener(_onAuthChanged);
    _groups = [];
    _membersByGroup.clear();
  }

  /// Loading the active group on sign-in is GlobalDataProvider's job (it explicitly calls
  /// [restoreActiveGroup] from splash and after sign-in/sign-up). This listener only
  /// handles the logout side, so a signed-out account's groups can't linger into the next
  /// login even if some future auth entry point skips GlobalDataProvider.resetAllData.
  void _onAuthChanged() {
    final isAuthenticated = authProvider.isAuthenticated;
    if (isAuthenticated == _wasAuthenticated) return;
    _wasAuthenticated = isAuthenticated;
    if (isAuthenticated) return;
    _groups = [];
    _activeGroupId = null;
    _membersByGroup.clear();
    _errorMessage = null;
    notifyListeners();
  }

  List<GroupModel> _groups = [];
  List<GroupModel> get groups => _groups;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _activeGroupId;
  String? get activeGroupId => _activeGroupId;

  /// Whether Tasks/Expenses/Groups should show data across every group rather than
  /// just [activeGroupId]. Shared here (rather than per-feature) so picking a scope
  /// in any one of those screens' filters is reflected in all of them.
  bool _showAllGroups = true;
  bool get showAllGroups => _showAllGroups;

  GroupModel? get activeGroup => _findGroup(_activeGroupId);

  String? nameForGroup(String? groupId) => _findGroup(groupId)?.name;

  final Map<String, List<GroupMemberModel>> _membersByGroup = {};
  final Set<String> _loadingMembersFor = {};

  List<GroupMemberModel> membersFor(String groupId) => _membersByGroup[groupId] ?? [];

  bool isLoadingMembers(String groupId) => _loadingMembersFor.contains(groupId);

  GroupModel? _findGroup(String? id) {
    if (id == null) return null;
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  /// Fetches the account's groups and re-resolves the active one against the persisted
  /// preference (falling back to the profile's server-synced default). Called explicitly
  /// by GlobalDataProvider.loadAllData, after profileProvider.loadProfile so the default is
  /// available - safe to call repeatedly across multiple sign-ins within the same session.
  Future<void> restoreActiveGroup() => _restore();

  Future<void> _restore() async {
    await loadGroups();
    await _resolveActiveGroup();
    notifyListeners();
  }

  /// Resolves [_activeGroupId]/[_showAllGroups] against whatever is currently in [_groups]
  /// (network-fetched or cached) - shared by [_restore], [primeFromCache] and [syncGroups]
  /// so all three compute the active group the same way instead of duplicating this logic.
  Future<void> _resolveActiveGroup() async {
    final localId = await groupPreferenceService.readActiveGroupId();
    // Falls back to the account's server-synced default when there's no local pick yet
    // (fresh install / new device) - see setActiveGroup, which keeps the two in sync.
    final defaultId = profileProvider.profile?.defaultGroupId;
    _activeGroupId = _findGroup(localId)?.id ?? _findGroup(defaultId)?.id ?? (_groups.isNotEmpty ? _groups.first.id : null);
    _showAllGroups = await groupPreferenceService.readShowAllGroups();
  }

  /// Populates from the local cache instantly, with no loading/error state - called once
  /// by GlobalDataProvider.primeFromCache() before Home is ever shown.
  Future<void> primeFromCache() async {
    final cached = groupRepository.cachedGroups();
    if (cached.isNotEmpty) _groups = cached;
    await _resolveActiveGroup();
    notifyListeners();
  }

  /// Background refresh from the network - called by GlobalDataProvider.syncAllData() on
  /// app open/resume/reconnect. Unlike [restoreActiveGroup], a failure here is silent: the
  /// cached/previous groups stay on screen rather than surfacing an error, since the user
  /// never asked for this reload.
  Future<void> syncGroups() async {
    try {
      _groups = await groupRepository.syncGroups();
      await _resolveActiveGroup();
      notifyListeners();
    } on GroupServiceException {
      // Swallowed by design - see doc comment above.
    }
  }

  /// Resets the group-scope choice back to "all groups" and wipes the persisted
  /// preference, so it doesn't linger into the next account signed in on this device.
  void resetShowAllGroupsPreference() {
    _showAllGroups = true;
    unawaited(groupPreferenceService.clearShowAllGroups());
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _groups = await groupService.listGroups();
    } on GroupServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GroupModel> createGroup(String name) async {
    final group = await groupService.createGroup(name);
    _groups = [group, ..._groups];
    await setActiveGroup(group.id);
    return group;
  }

  Future<GroupModel> joinGroup(String inviteCode) async {
    final group = await groupService.joinGroup(inviteCode);
    await loadGroups();
    await setActiveGroup(group.id);
    return group;
  }

  Future<void> setActiveGroup(String? groupId) async {
    _activeGroupId = groupId;
    notifyListeners();
    await groupPreferenceService.saveActiveGroupId(groupId);
    if (groupId != null) {
      unawaited(_syncDefaultGroup(groupId));
    }
  }

  /// Commits "all groups" vs a specific group at once - used by [TaskFilterSheet],
  /// [ExpenseFilterSheet], and [GroupsScreen] so switching scope from any one of them
  /// updates [showAllGroups]/[activeGroupId] for all of them together.
  Future<void> setGroupScope({required bool showAllGroups, String? groupId}) async {
    _showAllGroups = showAllGroups;
    if (!showAllGroups && groupId != null) {
      _activeGroupId = groupId;
    }
    notifyListeners();
    await groupPreferenceService.saveShowAllGroups(showAllGroups);
    if (!showAllGroups && groupId != null) {
      await groupPreferenceService.saveActiveGroupId(groupId);
      unawaited(_syncDefaultGroup(groupId));
    }
  }

  /// Best-effort sync of the active group to the server as the account default. Never
  /// blocks or surfaces an error - a failed sync just means the local switch (already
  /// applied above) won't be visible as the default on other devices yet.
  Future<void> _syncDefaultGroup(String groupId) async {
    try {
      await profileProvider.setDefaultGroup(groupId);
    } on ProfileServiceException {
      // Ignored - see doc comment above.
    }
  }

  Future<GroupModel> renameGroup(String groupId, String name) async {
    final original = _findGroup(groupId);
    final renamed = await groupService.renameGroup(groupId, name);
    final updated = renamed.role != null
        ? renamed
        : GroupModel(
            id: renamed.id,
            name: renamed.name,
            inviteCode: renamed.inviteCode,
            createdBy: renamed.createdBy,
            createdAt: renamed.createdAt,
            role: original?.role,
          );
    _groups = [for (final group in _groups) if (group.id == groupId) updated else group];
    notifyListeners();
    return updated;
  }

  Future<void> deleteGroup(String groupId) async {
    await groupService.deleteGroup(groupId);
    _groups = _groups.where((group) => group.id != groupId).toList();
    _membersByGroup.remove(groupId);
    if (_activeGroupId == groupId) {
      await setActiveGroup(_groups.isNotEmpty ? _groups.first.id : null);
    } else {
      notifyListeners();
    }
  }

  Future<void> loadMembers(String groupId) async {
    _loadingMembersFor.add(groupId);
    notifyListeners();
    try {
      _membersByGroup[groupId] = await groupService.listMembers(groupId);
    } on GroupServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _loadingMembersFor.remove(groupId);
      notifyListeners();
    }
  }
}
