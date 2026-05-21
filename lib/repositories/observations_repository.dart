import '../core/storage/local_cache_service.dart';
import '../models/observation.dart';
import '../services/observations_service.dart';

class ObservationsRepository {
  ObservationsRepository({
    required this.service,
    required this.cacheService,
  });

  final ObservationsService service;
  final LocalCacheService cacheService;

  Future<List<Observation>> loadObservations({
    bool refresh = false,
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    final cacheKey = _cacheKey(page: page, limit: limit, query: query);
    if (!refresh) {
      final cachedItems = await loadCachedObservations(page: page, limit: limit, query: query);
      if (cachedItems.isNotEmpty) {
        return cachedItems;
      }
    }

    final response = await service.fetchObservations(page: page, limit: limit, query: query);
    await cacheService.saveJson(cacheKey, response.items.map((item) => item.toJson()).toList());
    return response.items;
  }

  Future<List<Observation>> loadCachedObservations({
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    final cachedItems = await cacheService.readJsonList(_cacheKey(page: page, limit: limit, query: query));
    return cachedItems.map(Observation.fromJson).toList();
  }

  String _cacheKey({required int page, required int limit, String? query}) {
    return 'observations_cache_page_${page}_limit_${limit}_query_${query?.trim().toLowerCase().replaceAll(' ', '_') ?? 'all'}';
  }
}