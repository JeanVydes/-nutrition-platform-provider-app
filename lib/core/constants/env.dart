class Env {
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
  static const String accessToken = String.fromEnvironment('ACCESS_TOKEN', defaultValue: 'offline-token');
  static const String defaultAccountId = String.fromEnvironment(
    'DEFAULT_ACCOUNT_ID',
    defaultValue: '11111111-1111-4111-8111-111111111111',
  );
}
