import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/services/api_result.dart';
import 'package:manage_app/core/services/api_services.dart';
import 'package:manage_app/features/auth/models/user_model.dart';

class ProfileServiceException implements Exception {
  ProfileServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileService {
  ProfileService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<UserModel> getProfile() async {
    final result = await _api.get<UserModel>(
      AppUrls.profile,
      parser: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<UserModel> updateProfile({required String name, required String email, String? phone}) async {
    final result = await _api.patch<UserModel>(
      AppUrls.profile,
      data: {'name': name, 'email': email, 'phone': phone},
      parser: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  // Response is just {"defaultGroupId": "..."} - not a full profile - so there's nothing
  // to parse the caller doesn't already know from the groupId it passed in.
  Future<void> setDefaultGroup(String groupId) async {
    final result = await _api.put<void>(
      AppUrls.defaultGroup,
      data: {'groupId': groupId},
      parser: (_) {},
    );
    return _unwrap(result);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final result = await _api.post<void>(
      AppUrls.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      parser: (_) {},
    );
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw ProfileServiceException(failure.message));
  }
}

final profileService = ProfileService();
