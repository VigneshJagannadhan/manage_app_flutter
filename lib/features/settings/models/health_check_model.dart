class HealthCheckModel {
  final String status;
  final double uptime;
  final String db;

  const HealthCheckModel({required this.status, required this.uptime, required this.db});

  factory HealthCheckModel.fromJson(Map<String, dynamic> json) {
    return HealthCheckModel(
      status: json['status'] as String,
      uptime: (json['uptime'] as num).toDouble(),
      db: json['db'] as String,
    );
  }
}
