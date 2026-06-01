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
    if (!refresh && dateRange == null) {
      final cached = await loadCachedSnapshot();
      if (cached != null && cached.markers.isNotEmpty) {
        return cached;
      }
    }

    try {
      final snapshot = await service.fetchMapSnapshot(
        queryParameters: dateRange?.toQueryParams(),
      );
      await _saveSnapshot(snapshot);
      return snapshot;
    } catch (_) {
      final observations = await observationsRepository.loadObservations(
        refresh: refresh,
      );
      final derivedSnapshot = MapSnapshot.fromObservations(observations);
      await _saveSnapshot(derivedSnapshot);
      return derivedSnapshot;
    }
  }

  Future<void> _saveSnapshot(MapSnapshot snapshot) async {
    await cacheService.saveJson(_cacheKey, {
      'markers': snapshot.markers
          .map(
            (marker) => {
              'id': marker.id,
              'latitude': marker.position.latitude,
              'longitude': marker.position.longitude,
              'title': marker.title,
              'subtitle': marker.subtitle,
              'imageUrl': marker.imageUrl,
              'sourceUrl': marker.sourceUrl,
              'sourceType': marker.sourceType,
              'groupName': marker.groupName,
              'speciesId': marker.speciesId,
              'observedAt': marker.observedAt?.toIso8601String(),
            },
          )
          .toList(),
      'center': snapshot.center == null
          ? null
          : {
              'latitude': snapshot.center!.latitude,
              'longitude': snapshot.center!.longitude,
            },
      'zoom': snapshot.zoom,
    });
  }

  Future<MapSnapshot?> loadCachedSnapshot() async {
    final cachedValue = await cacheService.readJson(_cacheKey);
    if (cachedValue is Map<String, dynamic>) {
      return MapSnapshot.fromJson(cachedValue);
    }
    if (cachedValue is Map) {
      return MapSnapshot.fromJson(Map<String, dynamic>.from(cachedValue));
    }
    return null;
  }

  static const String _cacheKey = 'map_snapshot_cache';
}
