import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around [Connectivity] so callers depend on a project-owned type rather
/// than the plugin directly - same constructor-injectable + module-singleton shape as
/// [journalService]/[tokenStorageService].
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map((results) => !results.contains(ConnectivityResult.none));

  Future<bool> get isConnected async => !(await _connectivity.checkConnectivity()).contains(ConnectivityResult.none);
}

final connectivityService = ConnectivityService();
