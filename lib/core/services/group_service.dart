import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/services/api_result.dart';
import 'package:manage_app/core/services/api_services.dart';
import 'package:manage_app/features/group/models/group_member_model.dart';
import 'package:manage_app/features/group/models/group_model.dart';

class GroupServiceException implements Exception {
  GroupServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GroupService {
  GroupService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<GroupModel> createGroup(String name) async {
    final result = await _api.post<GroupModel>(
      AppUrls.groups,
      data: {'name': name},
      parser: (data) => GroupModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<List<GroupModel>> listGroups() async {
    final result = await _api.get<List<GroupModel>>(
      AppUrls.groups,
      parser: (data) => (data as List<dynamic>).map((group) => GroupModel.fromJson(group as Map<String, dynamic>)).toList(),
    );
    return _unwrap(result);
  }

  Future<GroupModel> joinGroup(String inviteCode) async {
    final result = await _api.post<GroupModel>(
      AppUrls.joinGroup,
      data: {'inviteCode': inviteCode},
      parser: (data) => GroupModel.fromJson((data as Map<String, dynamic>)['group'] as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<List<GroupMemberModel>> listMembers(String groupId) async {
    final result = await _api.get<List<GroupMemberModel>>(
      AppUrls.groupMembers(groupId),
      parser: (data) => (data as List<dynamic>).map((member) => GroupMemberModel.fromJson(member as Map<String, dynamic>)).toList(),
    );
    return _unwrap(result);
  }

  Future<GroupModel> renameGroup(String groupId, String name) async {
    final result = await _api.patch<GroupModel>(
      AppUrls.group(groupId),
      data: {'name': name},
      parser: (data) => GroupModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<void> deleteGroup(String groupId) async {
    final result = await _api.delete<void>(AppUrls.group(groupId), parser: (_) {});
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw GroupServiceException(failure.message));
  }
}

final groupService = GroupService();
