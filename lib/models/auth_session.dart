import 'app_user.dart';
import 'json_parsing.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final AppUser? user;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final nestedUser = readMap(json, ['user', 'account', 'profile']);
    return AuthSession(
      accessToken: readString(json, ['accessToken', 'access_token', 'token', 'jwt']) ?? '',
      refreshToken: readString(json, ['refreshToken', 'refresh_token']),
      expiresAt: readDateTime(json, ['expiresAt', 'expires_at', 'tokenExpiresAt']),
      user: nestedUser == null ? null : AppUser.fromJson(nestedUser),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt?.toIso8601String(),
        'user': user?.toJson(),
      };
}