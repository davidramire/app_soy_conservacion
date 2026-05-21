import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

enum BackendConnectionState { idle, checking, online, degraded, offline }

class BackendStatusProvider extends ChangeNotifier {
  BackendStatusProvider({
    required this.apiClient,
    required this.config,
  });

  final ApiClient apiClient;
  final AppConfig config;

  BackendConnectionState _state = BackendConnectionState.idle;
  String? _message;
  DateTime? _lastCheckedAt;

  BackendConnectionState get state => _state;
  String? get message => _message;
  DateTime? get lastCheckedAt => _lastCheckedAt;
  bool get isBusy => _state == BackendConnectionState.checking;

  Future<void> checkBackend() async {
    _state = BackendConnectionState.checking;
    _message = null;
    notifyListeners();

    try {
      await apiClient.getJson('/health', includeAuthorization: false);
      _state = BackendConnectionState.online;
      _message = 'Backend disponible';
    } on ApiException catch (error) {
      if (error.type == ApiExceptionType.notFound) {
        _state = BackendConnectionState.degraded;
        _message = 'Servidor accesible, pero falta /health';
      } else {
        _state = BackendConnectionState.offline;
        _message = error.message;
      }
    } catch (error) {
      _state = BackendConnectionState.offline;
      _message = error.toString();
    } finally {
      _lastCheckedAt = DateTime.now();
      notifyListeners();
    }
  }

  String get environmentLabel => config.environmentLabel;

  Uri get baseUri => config.apiBaseUri;
}