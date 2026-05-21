import '../core/network/api_client.dart';
import '../models/api_collection.dart';
import '../models/observation.dart';

class ObservationsService {
  ObservationsService({required this.apiClient});

  final ApiClient apiClient;

  Future<ApiCollection<Observation>> fetchObservations({
    int page = 1,
    int limit = 5000,
    String? query,
  }) async {
    final payload = await apiClient.getJson(
      '/observations',
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );

    return ApiCollection.fromJson(payload, Observation.fromJson);
  }
}