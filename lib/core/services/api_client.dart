import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:manage_app/core/constants/app_urls.dart';
import 'package:manage_app/core/services/auth_interceptor.dart';
import 'package:manage_app/core/services/token_storage_service.dart';

class ApiClient {
  ApiClient({TokenStorageService? storageService}) : dio = Dio(BaseOptions(baseUrl: _baseUrl, contentType: 'application/json')) {
    final tokenStorage = storageService ?? tokenStorageService;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await tokenStorage.readAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
    dio.interceptors.add(AuthInterceptor(dio: dio, tokenStorage: tokenStorage));
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  final Dio dio; 

  static const _baseUrl = AppUrls.baseUrl;
}
