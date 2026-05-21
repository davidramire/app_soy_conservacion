import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  const SecureTokenStorage();

  static const String _accessTokenKey = 'soy_conservacion_access_token';
  static const String _refreshTokenKey = 'soy_conservacion_refresh_token';
  static const String _sessionExpiryKey = 'soy_conservacion_session_expiry';

  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readSessionExpiry() => _storage.read(key: _sessionExpiryKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }

    if (expiresAt != null) {
      await _storage.write(key: _sessionExpiryKey, value: expiresAt.toIso8601String());
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionExpiryKey);
  }
}