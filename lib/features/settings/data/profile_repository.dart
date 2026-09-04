import 'package:huddle/core/data/json_cache.dart';
import 'package:huddle/features/auth/models/user_model.dart';
import 'package:huddle/features/settings/services/profile_service.dart';

/// Read-through cache for the account's profile - pure data access (fetch remote, mirror
/// to [cache]), no scheduling/retry policy. That lives in [ProfileProvider]; mirrors the
/// role [JournalRepository] plays for journal drafts.
class ProfileRepository {
  ProfileRepository({required this.remote, required this.cache});

  final ProfileService remote;
  final JsonCache cache;

  static const _key = 'profile';

  UserModel? cachedProfile() => cache.get(_key, UserModel.fromJson);

  Future<UserModel> syncProfile() async {
    final profile = await remote.getProfile();
    await cache.set(_key, profile.toJson());
    return profile;
  }
}
