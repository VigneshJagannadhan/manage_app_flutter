import 'package:huddle/features/settings/models/health_check_model.dart';
import 'package:huddle/features/settings/services/health_service.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

class SettingsProvider extends BaseProvider {
  SettingsProvider({required this.healthService});

  final HealthService healthService;

  @override
  void onInit() {}

  @override
  void onDispose() {}

  bool _isCheckingHealth = false;
  bool get isCheckingHealth => _isCheckingHealth;

  HealthCheckModel? _healthCheckResult;
  HealthCheckModel? get healthCheckResult => _healthCheckResult;

  String? _healthCheckError;
  String? get healthCheckError => _healthCheckError;

  bool _showDebugStuff = false;
  bool get showDebugStuff => _showDebugStuff;
  void toggleDebugStuff() {
    _showDebugStuff = !_showDebugStuff;
    notifyListeners();
  }

  Future<void> checkServerHealth() async {
    _isCheckingHealth = true;
    _healthCheckResult = null;
    _healthCheckError = null;
    notifyListeners();
    try {
      _healthCheckResult = await healthService.checkHealth();
    } on HealthServiceException catch (e) {
      _healthCheckError = e.message;
    } finally {
      _isCheckingHealth = false;
      notifyListeners();
    }
  }
}
