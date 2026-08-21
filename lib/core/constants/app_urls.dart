class AppUrls {
  static const String baseUrl = 'https://manage-app-api.onrender.com/api';
  static const String signUp = '/auth/signup';
  static const String signIn = '/auth/signin';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String tasks = '/tasks';
  static const String expenses = '/expenses';
  static const String health = '/health';
  static const String groups = '/groups';
  static const String journals = '/journals';
  static const String joinGroup = '/groups/join';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String defaultGroup = '/profile/default-group';

  static String group(String groupId) => '/groups/$groupId';
  static String groupMembers(String groupId) => '/groups/$groupId/members';
}
