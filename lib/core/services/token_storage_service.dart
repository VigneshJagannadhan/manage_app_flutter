import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manage_app/features/auth/models/auth_session_model.dart';
import 'package:manage_app/features/auth/models/token_pair_model.dart';
import 'package:manage_app/features/auth/models/user_model.dart';

/// Persists the signed-in session (tokens + user) in the platform secure store
/// (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android).
class TokenStorageService {
  TokenStorageService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  Future<void> saveSession(AuthSessionModel session) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: session.tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.tokens.refreshToken),
      _storage.write(key: _userKey, value: jsonEncode(session.user.toJson())),
    ]);
  }

  /// Updates the token pair only, leaving the stored user untouched. Used after a refresh call.
  Future<void> saveTokens(TokenPairModel tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
    ]);
  }

  Future<AuthSessionModel?> readSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userJson = await _storage.read(key: _userKey);
    if (accessToken == null || refreshToken == null || userJson == null) return null;
    return AuthSessionModel(
      user: UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
      tokens: TokenPairModel(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await Future.wait([_storage.delete(key: _accessTokenKey), _storage.delete(key: _refreshTokenKey), _storage.delete(key: _userKey)]);
  }
}

final tokenStorageService = TokenStorageService();
