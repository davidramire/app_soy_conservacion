import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironmentType { development, production }

class AppEnvironment {
  const AppEnvironment({
    required this.type,
    required this.developmentBaseUrl,
    required this.productionBaseUrl,
    required this.requestTimeout,
    required this.enableLogging,
    required this.mapboxAccessToken,
  });

  final AppEnvironmentType type;
  final Uri developmentBaseUrl;
  final Uri productionBaseUrl;
  final Duration requestTimeout;
  final bool enableLogging;
  final String? mapboxAccessToken;

  factory AppEnvironment.fromEnvironment() {
    final env = dotenv.env;
    final dartDefineEnv = const String.fromEnvironment('APP_ENV', defaultValue: '');
    final rawEnvironment = (dartDefineEnv.isNotEmpty ? dartDefineEnv : env['APP_ENV'])?.trim().toLowerCase();
    final environmentType = rawEnvironment == 'production' || rawEnvironment == 'prod'
        ? AppEnvironmentType.production
        : AppEnvironmentType.development;

    return AppEnvironment(
      type: environmentType,
      developmentBaseUrl: _parseUri(
        env['API_BASE_URL_DEV'],
        fallback: 'http://192.168.1.10:3000',
      ),
      productionBaseUrl: _parseUri(
        env['API_BASE_URL_PROD'],
        fallback: 'https://api.soyconservacion.com',
      ),
      requestTimeout: Duration(
        seconds: int.tryParse(env['API_TIMEOUT_SECONDS'] ?? '') ?? 20,
      ),
      enableLogging: (env['API_ENABLE_LOGGING'] ?? 'false').toLowerCase() == 'true',
      mapboxAccessToken: env['MAPBOX_ACCESS_TOKEN'],
    );
  }

  Uri get baseUri => type == AppEnvironmentType.production ? productionBaseUrl : developmentBaseUrl;

  String get label => type == AppEnvironmentType.production ? 'production' : 'development';

  bool get isProduction => type == AppEnvironmentType.production;
}

Uri _parseUri(String? value, {required String fallback}) {
  final candidate = (value == null || value.trim().isEmpty) ? fallback : value.trim();
  return Uri.parse(candidate);
}