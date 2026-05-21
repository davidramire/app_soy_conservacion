import '../core/storage/secure_token_storage.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({
    required this.service,
    required this.tokenStorage,
  });

  final AuthService service;
  final SecureTokenStorage tokenStorage;

  Future<AuthSession?> restoreSession() => service.restoreSession();

  Future<AuthSession> login({required String email, required String password}) {
    return service.login(email: email, password: password);
  }

  Future<AuthSession> refresh(String refreshToken) => service.refresh(refreshToken: refreshToken);

  Future<void> logout() => service.logout();

  Future<void> clearStoredSession() => tokenStorage.clear();
}