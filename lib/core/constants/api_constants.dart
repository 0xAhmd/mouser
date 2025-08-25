class ApiConstants {
  static const String baseUrl = 'http://';
  static const int defaultPort = 8080;
  static const String mouseEndpoint = '/mouse';
  static const String pingEndpoint = '/ping';
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration commandTimeout = Duration(milliseconds: 500);
}
