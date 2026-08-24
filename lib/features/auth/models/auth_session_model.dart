import 'package:huddle/features/auth/models/token_pair_model.dart';
import 'package:huddle/features/auth/models/user_model.dart';

/// Response shape shared by the signup and signin endpoints.
class AuthSessionModel {
  final UserModel user;
  final TokenPairModel tokens;

  const AuthSessionModel({required this.user, required this.tokens});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(user: UserModel.fromJson(json['user'] as Map<String, dynamic>), tokens: TokenPairModel.fromJson(json));
  }
}
