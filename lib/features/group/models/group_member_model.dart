import 'package:manage_app/core/enums/group_enums.dart';

class GroupMemberModel {
  final String userId;
  final String name;
  final String email;
  final GroupRole role;
  final DateTime joinedAt;

  GroupMemberModel({required this.userId, required this.name, required this.email, required this.role, required this.joinedAt});

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: GroupRoleApi.fromApiValue(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) => other is GroupMemberModel && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
