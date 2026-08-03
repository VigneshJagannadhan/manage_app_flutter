import 'dart:async';

import 'package:manage_app/core/services/group_preference_service.dart';
import 'package:manage_app/core/services/group_service.dart';
import 'package:manage_app/features/group/models/group_member_model.dart';
import 'package:manage_app/features/group/models/group_model.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class GroupProvider extends BaseProvider {
  GroupProvider({required this.groupService, required this.groupPreferenceService});

  final GroupService groupService;
  final GroupPreferenceService groupPreferenceService;

  final Completer<void> _readyCompleter = Completer<void>();

  /// Resolves once the persisted active group has been restored. Task/Expense providers
  /// await this before their first load so they don't fetch in "all groups" mode just
  /// because group restoration is still in flight.
  Future<void> get ready => _readyCompleter.future;

  @override
  void onInit() {
    _restore();
  }

  @override
  void onDispose() {
    _groups = [];
    _membersByGroup.clear();
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

  Future<void> _restore() async {
    await loadGroups();
    final savedId = await groupPreferenceService.readActiveGroupId();
    _activeGroupId = _findGroup(savedId)?.id ?? (_groups.isNotEmpty ? _groups.first.id : null);
    notifyListeners();
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
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
