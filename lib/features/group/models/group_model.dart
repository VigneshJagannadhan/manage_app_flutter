import 'package:manage_app/core/enums/group_enums.dart';

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  // Absent on the plain create response - only `GET /api/groups` includes it.
  final GroupRole? role;

  GroupModel({required this.id, required this.name, required this.inviteCode, required this.createdBy, required this.createdAt, this.role});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      role: json['role'] != null ? GroupRoleApi.fromApiValue(json['role'] as String) : null,
    );
  }
}
