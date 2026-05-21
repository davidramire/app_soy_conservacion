import '../core/network/api_client.dart';
import '../models/api_collection.dart';
import '../models/species.dart';

class SpeciesService {
  SpeciesService({required this.apiClient});

  final ApiClient apiClient;

  Future<ApiCollection<Species>> fetchSpecies({
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    final payload = await apiClient.getJson(
      '/species',
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );

    return ApiCollection.fromJson(payload, Species.fromJson);
  }
}