import '../core/storage/local_cache_service.dart';
import '../models/species.dart';
import '../services/species_service.dart';

class SpeciesRepository {
  SpeciesRepository({
    required this.service,
    required this.cacheService,
  });

  final SpeciesService service;
  final LocalCacheService cacheService;

  Future<List<Species>> loadSpecies({
    bool refresh = false,
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    final cacheKey = _cacheKey(page: page, limit: limit, query: query);
    if (!refresh) {
      final cachedItems = await loadCachedSpecies(page: page, limit: limit, query: query);
      if (cachedItems.isNotEmpty) {
        return cachedItems;
      }
    }

    final response = await service.fetchSpecies(page: page, limit: limit, query: query);
    await cacheService.saveJson(cacheKey, response.items.map((item) => item.toJson()).toList());
    return response.items;
  }

  Future<List<Species>> loadCachedSpecies({
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    final cachedItems = await cacheService.readJsonList(_cacheKey(page: page, limit: limit, query: query));
    return cachedItems.map(Species.fromJson).toList();
  }

  String _cacheKey({required int page, required int limit, String? query}) {
    return 'species_cache_page_${page}_limit_${limit}_query_${query?.trim().toLowerCase().replaceAll(' ', '_') ?? 'all'}';
  }
}