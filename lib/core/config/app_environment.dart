enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromName(String value) {
    return AppEnvironment.values.firstWhere(
      (env) => env.name == value.toLowerCase(),
      orElse: () => AppEnvironment.dev,
    );
  }

  bool get isProduction => this == AppEnvironment.prod;
}
