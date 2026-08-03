import 'package:dio/dio.dart';
import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/services/session_expired_notifier.dart';
import 'package:manage_app/core/services/token_storage_service.dart';
import 'package:manage_app/features/auth/models/token_pair_model.dart';

const _retriedKey = 'authInterceptorRetried';

/// Transparently refreshes the access token when a request comes back 401 and retries it
/// once, so a stale token never surfaces as a raw API error to the user. Concurrent 401s
/// share a single in-flight refresh call.
///
/// If the refresh token itself is rejected, the session is unrecoverable: the stored
/// session is cleared and [sessionExpiredNotifier] fires so the app can return to
/// sign-in. Any other refresh failure (network blip, server error) is treated as
/// transient - the original error surfaces normally so the user's existing "Retry"
/// action can try again.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorageService tokenStorage;

  Future<String?>? _refreshing;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == AppUrls.refreshToken;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (!isUnauthorized || isRefreshCall || alreadyRetried) {
      return handler.next(err);
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      return handler.next(err);
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      retryOptions.extra[_retriedKey] = true;
      final response = await dio.fetch(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await dio.post(
        AppUrls.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_retriedKey: true}),
      );
      final tokens = TokenPairModel.fromJson(response.data as Map<String, dynamic>);
      await tokenStorage.saveTokens(tokens);
      return tokens.accessToken;
    } on DioException catch (e) {
      final refreshTokenRejected = e.response?.statusCode == 401 || e.response?.statusCode == 403;
      if (refreshTokenRejected) {
        await tokenStorage.clear();
        sessionExpiredNotifier.notifySessionExpired();
      }
      return null;
    }
  }
}
