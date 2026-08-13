class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? defaultGroupId;

  const UserModel({required this.id, required this.name, required this.email, this.phone, this.defaultGroupId});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      defaultGroupId: json['defaultGroupId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'defaultGroupId': defaultGroupId};
}
