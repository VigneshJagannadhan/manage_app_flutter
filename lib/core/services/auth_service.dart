import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/services/api_result.dart';
import 'package:manage_app/core/services/api_services.dart';
import 'package:manage_app/features/auth/models/auth_session_model.dart';
import 'package:manage_app/features/auth/models/token_pair_model.dart';

class AuthServiceException implements Exception {
  AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<AuthSessionModel> signUp({required String name, required String email, required String password}) async {
    final result = await _api.post<AuthSessionModel>(
      AppUrls.signUp,
      data: {'name': name, 'email': email, 'password': password},
      parser: (data) => AuthSessionModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<AuthSessionModel> signIn({required String email, required String password}) async {
    final result = await _api.post<AuthSessionModel>(
      AppUrls.signIn,
      data: {'email': email, 'password': password},
      parser: (data) => AuthSessionModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<TokenPairModel> refresh({required String refreshToken}) async {
    final result = await _api.post<TokenPairModel>(
      AppUrls.refreshToken,
      data: {'refreshToken': refreshToken},
      parser: (data) => TokenPairModel.fromJson(data as Map<String, dynamic>),
    );
    return _unwrap(result);
  }

  Future<void> logout({required String refreshToken}) async {
    final result = await _api.post<void>(AppUrls.logout, data: {'refreshToken': refreshToken}, parser: (_) {});
    return _unwrap(result);
  }

  T _unwrap<T>(ApiResult<T> result) {
    return result.when(success: (data) => data, failure: (failure) => throw AuthServiceException(failure.message));
  }
}

final authService = AuthService();
