class AppUrls {
  static const String baseUrl = 'https://manage-app-api.onrender.com/api';
  static const String devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static const String signUp = '/auth/signup';
  static const String signIn = '/auth/signin';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String tasks = '/tasks';
  static const String expenses = '/expenses';
  static const String health = '/health';
  static const String groups = '/groups';
  static const String joinGroup = '/groups/join';

  static String groupMembers(String groupId) => '/groups/$groupId/members';
}
