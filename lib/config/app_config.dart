import 'app_environment.dart';

class AppConfig {
  const AppConfig({required this.environment});

  final AppEnvironment environment;

  factory AppConfig.fromEnvironment() => AppConfig(environment: AppEnvironment.fromEnvironment());

  Uri get apiBaseUri => environment.baseUri;

  Duration get requestTimeout => environment.requestTimeout;

  bool get enableLogging => environment.enableLogging;

  String get environmentLabel => environment.label;

  bool get isProduction => environment.isProduction;

  String? get mapboxAccessToken => environment.mapboxAccessToken;
}