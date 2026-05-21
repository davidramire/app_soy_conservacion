import '../core/network/api_client.dart';
import '../core/storage/secure_token_storage.dart';
import '../models/auth_session.dart';

class AuthService {
  AuthService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final SecureTokenStorage tokenStorage;

  Future<AuthSession> login({required String email, required String password}) async {
    final payload = await apiClient.postJson(
      '/auth/login',
      includeAuthorization: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final session = _parseSession(payload);
    await tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final refreshToken = await tokenStorage.readRefreshToken();
    final expiryRaw = await tokenStorage.readSessionExpiry();
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiryRaw == null ? null : DateTime.tryParse(expiryRaw),
    );
  }

  Future<AuthSession> refresh({required String refreshToken}) async {
    final payload = await apiClient.postJson(
      '/auth/refresh',
      includeAuthorization: false,
      body: {'refreshToken': refreshToken},
    );

    final session = _parseSession(payload);
    await tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    return session;
  }

  Future<void> logout() async {
    try {
      await apiClient.postJson('/auth/logout');
    } finally {
      await tokenStorage.clear();
    }
  }

  AuthSession _parseSession(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return AuthSession.fromJson(payload);
    }
    if (payload is Map) {
      return AuthSession.fromJson(Map<String, dynamic>.from(payload));
    }
    throw const FormatException('La respuesta de autenticación no es válida.');
  }
}