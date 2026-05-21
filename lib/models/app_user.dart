import 'json_parsing.dart';

class AppUser {
  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.avatarUrl,
  });

  final String id;
  final String? name;
  final String? email;
  final String? role;
  final String? avatarUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: readString(json, ['id', '_id', 'uuid']) ?? '',
      name: readString(json, ['name', 'fullName', 'displayName']),
      email: readString(json, ['email']),
      role: readString(json, ['role', 'type', 'accountType']),
      avatarUrl: readString(json, ['avatarUrl', 'avatar_url', 'photoUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatarUrl': avatarUrl,
      };
}