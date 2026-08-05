import 'package:manage_app/core/services/session_expired_notifier.dart';
import 'package:manage_app/features/auth/models/user_model.dart';
import 'package:manage_app/features/settings/services/profile_service.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class ProfileProvider extends BaseProvider {
  ProfileProvider({required this.profileService});

  final ProfileService profileService;

  @override
  void onInit() {
    sessionExpiredNotifier.addListener(clearProfile);
  }

  @override
  void onDispose() {
    sessionExpiredNotifier.removeListener(clearProfile);
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _profile;
  UserModel? get profile => _profile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await profileService.getProfile();
    } on ProfileServiceException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> updateProfile({required String name, required String email, String? phone}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await profileService.updateProfile(name: name, email: email, phone: phone);
      return _profile;
    } on ProfileServiceException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Drops the cached profile so a subsequent sign-in (possibly as a different user)
  /// doesn't briefly show the previous user's data. Call on sign-out too.
  void clearProfile() {
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    _isChangingPassword = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await profileService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return true;
    } on ProfileServiceException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }
}
