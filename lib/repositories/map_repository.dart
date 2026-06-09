import '../core/storage/local_cache_service.dart';
import '../models/map_snapshot.dart';
import '../providers/filter_provider.dart';
import '../services/map_service.dart';
import 'observations_repository.dart';

class MapRepository {
  MapRepository({
    required this.service,
    required this.observationsRepository,
    required this.cacheService,
  });

  final MapService service;
  final ObservationsRepository observationsRepository;
  final LocalCacheService cacheService;

  Future<MapSnapshot> loadMapSnapshot({
    bool refresh = false,
    DateRangeFilter? dateRange,
  }) async {
    final cacheKey = 'map_snapshot_${dateRange?.from.millisecondsSinceEpoch}_${dateRange?.to.millisecondsSinceEpoch}';

    if (!refresh) {
      final cachedJson = await cacheService.readJson(cacheKey);
      if (cachedJson != null) {
        return MapSnapshot.fromJson(cachedJson);
      }
    }

    try {
      final fetchFuture = service.fetchMapSnapshot(
        queryParameters: dateRange?.toQueryParams(),
      );
      final snapshot = refresh ? await fetchFuture : await fetchFuture.timeout(const Duration(seconds: 2));
      await cacheService.saveJson(cacheKey, snapshot.toJson());
      return snapshot;
    } catch (_) {
      final cachedJson = await cacheService.readJson(cacheKey);
      if (cachedJson != null) {
        return MapSnapshot.fromJson(cachedJson);
      }
      
      final baseCachedJson = await cacheService.readJson('map_snapshot_null_null');
      if (baseCachedJson != null) {
        final baseSnapshot = MapSnapshot.fromJson(baseCachedJson);
        var filteredMarkers = baseSnapshot.markers;
        if (dateRange != null) {
          filteredMarkers = filteredMarkers.where((m) {
            if (m.observedAt == null) return false;
            final isAfter = m.observedAt!.isAfter(dateRange.from) || m.observedAt!.isAtSameMomentAs(dateRange.from);
            final isBefore = m.observedAt!.isBefore(dateRange.to) || m.observedAt!.isAtSameMomentAs(dateRange.to);
            return isAfter && isBefore;
          }).toList();
        }
        return MapSnapshot(
          markers: filteredMarkers,
          center: baseSnapshot.center,
          zoom: baseSnapshot.zoom,
        );
      }
      
      return const MapSnapshot(markers: []);
    }
  }
}
