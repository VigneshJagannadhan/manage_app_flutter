import 'package:manage_app/core/services/auth_service.dart';
import 'package:manage_app/core/services/session_expired_notifier.dart';
import 'package:manage_app/core/services/token_storage_service.dart';
import 'package:manage_app/features/auth/models/auth_session_model.dart';
import 'package:manage_app/features/auth/models/user_model.dart';
import 'package:manage_app/features/shared/providers/base_provider.dart';

class AuthProvider extends BaseProvider {
  AuthProvider({required this.authService, required this.tokenStorageService});

  final AuthService authService;
  final TokenStorageService tokenStorageService;

  @override
  void onInit() {
    sessionExpiredNotifier.addListener(_handleSessionExpired);
  }

  @override
  void onDispose() {
    sessionExpiredNotifier.removeListener(_handleSessionExpired);
  }

  /// The token storage is already cleared by the interceptor that detected the dead
  /// refresh token - this just resets in-memory state so `isAuthenticated` reflects it.
  void _handleSessionExpired() {
    _currentUser = null;
    notifyListeners();
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Restores a previously signed-in session from secure storage. Call once at startup
  /// and await it before deciding whether to route to sign-in or straight into the app.
  Future<void> restoreSession() async {
    final session = await tokenStorageService.readSession();
    _currentUser = session?.user;
    notifyListeners();
  }

  Future<bool> signUp({required String name, required String email, required String password}) {
    return _authenticate(() => authService.signUp(name: name, email: email, password: password));
  }

  Future<bool> signIn({required String email, required String password}) {
    return _authenticate(() => authService.signIn(email: email, password: password));
  }

  Future<bool> _authenticate(Future<AuthSessionModel> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final session = await action();
      await tokenStorageService.saveSession(session);
      _currentUser = session.user;
      return true;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Syncs a freshly edited profile back into in-memory and persisted session state.
  Future<void> updateCurrentUser(UserModel user) async {
    _currentUser = user;
    notifyListeners();
    await tokenStorageService.updateUser(user);
  }

  Future<void> signOut() async {
    final refreshToken = await tokenStorageService.readRefreshToken();
    _isLoading = true;
    notifyListeners();
    try {
      if (refreshToken != null) await authService.logout(refreshToken: refreshToken);
    } on AuthServiceException {
      // Best-effort: the local session is cleared below regardless of server outcome.
    } finally {
      await tokenStorageService.clear();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
