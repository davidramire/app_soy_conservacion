import '../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/api_collection.dart';

class UsersService {
  UsersService({required this.apiClient});

  final ApiClient apiClient;

  Future<ApiCollection<AppUser>> fetchUsers({int page = 1, int limit = 50}) async {
    final payload = await apiClient.getJson(
      '/users',
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
      },
    );

    return ApiCollection.fromJson(payload, AppUser.fromJson);
  }

  Future<AppUser> fetchProfile() async {
    final payload = await apiClient.getJson('/users/me');
    if (payload is Map<String, dynamic>) {
      return AppUser.fromJson(payload);
    }

    if (payload is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(payload));
    }

    throw const FormatException('La respuesta del perfil no es válida.');
  }
}