enum AppEnvironment {
  dev,
  prod;

  static AppEnvironment fromName(String name) {
    return switch (name.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'dev' || 'development' => AppEnvironment.dev,
      _ => AppEnvironment.dev,
    };
  }
}

class AppConfig {
  static const String _environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static final AppEnvironment environment =
      AppEnvironment.fromName(_environmentName);

  static bool get isProduction => environment == AppEnvironment.prod;

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    return switch (environment) {
      AppEnvironment.dev => 'http://localhost:3001',
      AppEnvironment.prod => 'https://api.example.com',
    };
  }
}
