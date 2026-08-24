import 'package:huddle/core/constants/app_urls.dart';
import 'package:huddle/core/services/api_services.dart';
import 'package:huddle/features/settings/models/health_check_model.dart';

class HealthServiceException implements Exception {
  HealthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HealthService {
  HealthService({ApiServices? api}) : _api = api ?? apiServices;

  final ApiServices _api;

  Future<HealthCheckModel> checkHealth() async {
    final result = await _api.get<HealthCheckModel>(
      AppUrls.health,
      parser: (data) => HealthCheckModel.fromJson(data as Map<String, dynamic>),
    );
    return result.when(success: (data) => data, failure: (failure) => throw HealthServiceException(failure.message));
  }
}

final healthService = HealthService();
