import 'dart:async';

import 'package:manage_app/core/services/group_preference_service.dart';
import 'package:manage_app/core/services/group_service.dart';
import 'package:manage_app/features/auth/providers/auth_provider.dart';
import 'package:manage_app/features/group/models/group_member_model.dart';
import 'package:manage_app/features/group/models/group_model.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/settings/services/profile_service.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class GroupProvider extends BaseProvider {
  GroupProvider({
    required this.groupService,
    required this.groupPreferenceService,
    required this.authProvider,
    required this.profileProvider,
  });

  final GroupService groupService;
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

  /// Loading the active group on sign-in is AppProvider's job (it explicitly calls
  /// [restoreActiveGroup] from splash and after sign-in/sign-up). This listener only
  /// handles the logout side, so a signed-out account's groups can't linger into the next
  /// login even if some future auth entry point skips AppProvider.resetAllData.
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
  /// by AppProvider.loadAllData, after profileProvider.loadProfile so the default is
  /// available - safe to call repeatedly across multiple sign-ins within the same session.
  Future<void> restoreActiveGroup() => _restore();

  Future<void> _restore() async {
    await loadGroups();
    final localId = await groupPreferenceService.readActiveGroupId();
    // Falls back to the account's server-synced default when there's no local pick yet
    // (fresh install / new device) - see setActiveGroup, which keeps the two in sync.
    final defaultId = profileProvider.profile?.defaultGroupId;
    _activeGroupId = _findGroup(localId)?.id ?? _findGroup(defaultId)?.id ?? (_groups.isNotEmpty ? _groups.first.id : null);
    notifyListeners();
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
