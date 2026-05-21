import '../core/storage/local_cache_service.dart';
import '../models/map_snapshot.dart';
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

  Future<MapSnapshot> loadMapSnapshot({bool refresh = false}) async {
    if (!refresh) {
      final cached = await loadCachedSnapshot();
      if (cached != null) {
        return cached;
      }
    }

    try {
      final snapshot = await service.fetchMapSnapshot();
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
      return snapshot;
    } catch (_) {
      final observations = await observationsRepository.loadObservations(refresh: refresh);
      final derivedSnapshot = MapSnapshot.fromObservations(observations);
      await cacheService.saveJson(_cacheKey, {
        'markers': derivedSnapshot.markers
            .map(
              (marker) => {
                'id': marker.id,
                'latitude': marker.position.latitude,
                'longitude': marker.position.longitude,
                'title': marker.title,
                'subtitle': marker.subtitle,
                'imageUrl': marker.imageUrl,
              },
            )
            .toList(),
        'center': derivedSnapshot.center == null
            ? null
            : {
                'latitude': derivedSnapshot.center!.latitude,
                'longitude': derivedSnapshot.center!.longitude,
              },
        'zoom': derivedSnapshot.zoom,
      });
      return derivedSnapshot;
    }
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