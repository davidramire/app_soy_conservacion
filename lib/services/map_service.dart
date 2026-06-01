import '../core/network/api_client.dart';
import '../models/map_snapshot.dart';

class MapService {
  MapService({required this.apiClient});

  final ApiClient apiClient;

  Future<MapSnapshot> fetchMapSnapshot({
    int limit = 5000,
    Map<String, String>? queryParameters,
  }) async {
    final payload = await apiClient.getJson(
      '/map',
      queryParameters: {
        'limit': '$limit',
        ...?queryParameters,
      },
    );

    return MapSnapshot.fromJson(payload);
  }
}