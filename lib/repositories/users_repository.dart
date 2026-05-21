import '../models/app_user.dart';
import '../services/users_service.dart';

class UsersRepository {
  UsersRepository({required this.service});

  final UsersService service;

  Future<List<AppUser>> loadUsers({int page = 1, int limit = 50}) async {
    final response = await service.fetchUsers(page: page, limit: limit);
    return response.items;
  }

  Future<AppUser> loadProfile() => service.fetchProfile();
}