class Env {
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
  static const String securityBaseUrl = String.fromEnvironment(
    'SECURITY_BASE_URL',
    defaultValue: 'https://mriai.coreunimag.com/api/auth',
  );
}
