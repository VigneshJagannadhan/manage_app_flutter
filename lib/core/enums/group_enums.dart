enum GroupRole { owner, member }

extension GroupRoleApi on GroupRole {
  /// Matches the backend's case-sensitive role string exactly.
  String get apiValue => switch (this) {
    GroupRole.owner => 'OWNER',
    GroupRole.member => 'MEMBER',
  };

  static GroupRole fromApiValue(String value) => switch (value) {
    'OWNER' => GroupRole.owner,
    'MEMBER' => GroupRole.member,
    _ => throw ArgumentError('Unknown group role: $value'),
  };
}
