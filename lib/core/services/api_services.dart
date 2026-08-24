import 'package:dio/dio.dart';
import 'package:huddle/core/services/api_client.dart';
import 'package:huddle/core/services/api_result.dart';

class ApiServices {
  ApiServices({ApiClient? apiClient}) : _dio = (apiClient ?? ApiClient()).dio;

  final Dio _dio;

  Future<ApiResult<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, required T Function(dynamic data) parser}) {
    return _request(() => _dio.get(path, queryParameters: queryParameters), parser);
  }

  Future<ApiResult<T>> post<T>(String path, {dynamic data, required T Function(dynamic data) parser}) {
    return _request(() => _dio.post(path, data: data), parser);
  }

  Future<ApiResult<T>> put<T>(String path, {dynamic data, required T Function(dynamic data) parser}) {
    return _request(() => _dio.put(path, data: data), parser);
  }

  Future<ApiResult<T>> patch<T>(String path, {dynamic data, required T Function(dynamic data) parser}) {
    return _request(() => _dio.patch(path, data: data), parser);
  }

  Future<ApiResult<T>> delete<T>(String path, {dynamic data, required T Function(dynamic data) parser}) {
    return _request(() => _dio.delete(path, data: data), parser);
  }

  Future<ApiResult<T>> _request<T>(Future<Response> Function() call, T Function(dynamic data) parser) async {
    try {
      final response = await call();
      return ApiSuccess(parser(response.data));
    } on DioException catch (e) {
      return ApiError(_failureFrom(e));
    }
  }

  Failure _failureFrom(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const Failure('The request timed out. Please try again.', type: FailureType.timeout);
      case DioExceptionType.connectionError:
        return const Failure('No internet connection. Please check your network.', type: FailureType.noConnection);
      case DioExceptionType.cancel:
        return const Failure('Request was cancelled.', type: FailureType.cancelled);
      case DioExceptionType.badCertificate:
        return const Failure('Could not establish a secure connection.', type: FailureType.badCertificate);
      case DioExceptionType.badResponse:
        return _badResponseFailure(e);
      case DioExceptionType.unknown:
        return Failure(e.message ?? 'Something went wrong. Please try again.', type: FailureType.unknown);
    }
  }

  Failure _badResponseFailure(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    // For authenticated requests, a 401 always means the (already refresh-attempted)
    // session is invalid - show the friendly default rather than a raw backend string
    // like "invalid or expired access token". Unauthenticated calls (sign in/up) keep
    // their specific backend message (e.g. "Invalid email or password").
    final isAuthenticatedRequest = e.requestOptions.headers.containsKey('Authorization');
    final message = (statusCode == 401 && isAuthenticatedRequest)
        ? _defaultMessageFor(statusCode)
        : (_messageFromResponseBody(data) ?? _defaultMessageFor(statusCode));
    return Failure(message, statusCode: statusCode, type: FailureType.badResponse);
  }

  String? _messageFromResponseBody(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'] ?? data['error'];
    return message is String ? message : null;
  }

  String _defaultMessageFor(int? statusCode) {
    return switch (statusCode) {
      400 => 'Invalid request. Please check the details and try again.',
      401 => 'Your session has expired. Please log in again.',
      403 => 'You don\'t have permission to do that.',
      404 => 'The requested resource could not be found.',
      409 => 'This conflicts with existing data.',
      422 => 'Some of the submitted data is invalid.',
      429 => 'Too many requests. Please wait a moment and try again.',
      int code when code >= 500 => 'Something went wrong on our end. Please try again later.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

final apiServices = ApiServices();
