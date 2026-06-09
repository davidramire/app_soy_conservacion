import '../core/storage/local_cache_service.dart';
import '../models/map_snapshot.dart';
import '../providers/filter_provider.dart';
import '../services/analytics_service.dart';
import 'observations_repository.dart';

class AnalyticsRepository {
  AnalyticsRepository({
    required this.service,
    required this.cacheService,
    required this.observationsRepository,
  });

  final AnalyticsService service;
  final LocalCacheService cacheService;
  final ObservationsRepository observationsRepository;

  Future<DateBounds> loadDateBounds({bool refresh = false}) async {
    const cacheKey = 'analytics_date_bounds';
    if (!refresh) {
      final cachedJson = await cacheService.readJson(cacheKey);
      if (cachedJson != null) {
        return DateBounds.fromJson(cachedJson);
      }
    }

    try {
      final fetchFuture = service.fetchDateBounds();
      final data = refresh ? await fetchFuture : await fetchFuture.timeout(const Duration(seconds: 2));
      await cacheService.saveJson(cacheKey, data.toJson());
      return data;
    } catch (_) {
      final cachedJson = await cacheService.readJson(cacheKey);
      if (cachedJson != null) {
        return DateBounds.fromJson(cachedJson);
      }
      rethrow;
    }
  }

  Future<List<TaxonomicGroupStat>> loadTaxonomicGroups({
    bool refresh = false,
    DateRangeFilter? dateRange,
    String source = 'all',
  }) async {
    final cacheKey = 'analytics_groups_${source}_${dateRange?.from.toIso8601String()}_${dateRange?.to.toIso8601String()}';
    
    if (!refresh) {
      final cachedItems = await cacheService.readJsonList(cacheKey);
      if (cachedItems.isNotEmpty) {
        return cachedItems.map(TaxonomicGroupStat.fromJson).toList();
      }
    }

    try {
      final fetchFuture = service.fetchTaxonomicGroups(dateRange: dateRange, source: source);
      final data = refresh ? await fetchFuture : await fetchFuture.timeout(const Duration(seconds: 2));
      await cacheService.saveJson(cacheKey, data.map((e) => e.toJson()).toList());
      return data;
    } catch (_) {
      final cachedItems = await cacheService.readJsonList(cacheKey);
      if (cachedItems.isNotEmpty) {
        return cachedItems.map(TaxonomicGroupStat.fromJson).toList();
      }
      
      final baseCachedJson = await cacheService.readJson('map_snapshot_null_null');
      final markers = baseCachedJson != null ? MapSnapshot.fromJson(baseCachedJson).markers : <MapMarkerData>[];
      
      var filtered = markers;
      if (dateRange != null) {
        filtered = filtered.where((m) {
          if (m.observedAt == null) return false;
          final isAfter = m.observedAt!.isAfter(dateRange.from) || m.observedAt!.isAtSameMomentAs(dateRange.from);
          final isBefore = m.observedAt!.isBefore(dateRange.to) || m.observedAt!.isAtSameMomentAs(dateRange.to);
          return isAfter && isBefore;
        }).toList();
      }
      if (source != 'all') {
         filtered = filtered.where((m) {
           return m.resolvedSourceType == source;
         }).toList();
      }
      
      final groupsMap = <String, int>{};
      for (final m in filtered) {
        final g = m.groupName?.isEmpty == false ? m.groupName! : 'Desconocido';
        groupsMap[g] = (groupsMap[g] ?? 0) + 1;
      }
      return groupsMap.entries.map((e) => TaxonomicGroupStat(name: e.key, total: e.value)).toList();
    }
  }

  Future<List<UserRankingItem>> loadUserRanking({
    bool refresh = false,
    DateRangeFilter? dateRange,
    String source = 'all',
    int limit = 100,
  }) async {
    final cacheKey = 'analytics_users_${source}_${limit}_${dateRange?.from.toIso8601String()}_${dateRange?.to.toIso8601String()}';
    
    if (!refresh) {
      final cachedItems = await cacheService.readJsonList(cacheKey);
      if (cachedItems.isNotEmpty) {
        return cachedItems.map(UserRankingItem.fromJson).toList();
      }
    }

    try {
      final fetchFuture = service.fetchUserRanking(dateRange: dateRange, source: source, limit: limit);
      final data = refresh ? await fetchFuture : await fetchFuture.timeout(const Duration(seconds: 2));
      await cacheService.saveJson(cacheKey, data.map((e) => e.toJson()).toList());
      return data;
    } catch (_) {
      final cachedItems = await cacheService.readJsonList(cacheKey);
      if (cachedItems.isNotEmpty) {
        return cachedItems.map(UserRankingItem.fromJson).toList();
      }
      
      final baseCachedJson = await cacheService.readJson('map_snapshot_null_null');
      final markers = baseCachedJson != null ? MapSnapshot.fromJson(baseCachedJson).markers : <MapMarkerData>[];
      
      var filtered = markers;
      if (dateRange != null) {
        filtered = filtered.where((m) {
          if (m.observedAt == null) return false;
          final isAfter = m.observedAt!.isAfter(dateRange.from) || m.observedAt!.isAtSameMomentAs(dateRange.from);
          final isBefore = m.observedAt!.isBefore(dateRange.to) || m.observedAt!.isAtSameMomentAs(dateRange.to);
          return isAfter && isBefore;
        }).toList();
      }
      if (source != 'all') {
         filtered = filtered.where((m) {
           return m.resolvedSourceType == source;
         }).toList();
      }
      
      final usersMap = <String, int>{};
      for (final m in filtered) {
        final u = m.subtitle?.isEmpty == false ? m.subtitle! : 'Anónimo';
        usersMap[u] = (usersMap[u] ?? 0) + 1;
      }
      final sorted = usersMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(limit).map((e) => UserRankingItem(username: e.key, total: e.value)).toList();
    }
  }

  Future<List<SpeciesRankingItem>> loadSpeciesRanking({
    bool refresh = false,
    DateRangeFilter? dateRange,
    String source = 'all',
    int limit = 100,
  }) async {
    final cacheKey = 'analytics_species_${source}_${limit}_${dateRange?.from.toIso8601String()}_${dateRange?.to.toIso8601String()}';
    
    if (!refresh) {
      final cachedItems = await cacheService.readJsonList(cacheKey);
      if (cachedItems.isNotEmpty) {
        return cachedItems.map(SpeciesRankingItem.fromJson).toList();
      }
    }

    try {
      final fetchFuture = service.fetchSpeciesRanking(dateRange: dateRange, source: source, limit: limit);
      final data = refresh ? await fetchFuture : await fetchFuture.timeout(const Duration(seconds: 2));
      await cacheService.saveJson(cacheKey, data.map((e) => e.toJson()).toList());
      return data;
    } catch (_) {
      final cachedItems = await cacheService.readJsonList(cacheKey);
      if (cachedItems.isNotEmpty) {
        return cachedItems.map(SpeciesRankingItem.fromJson).toList();
      }
      
      final baseCachedJson = await cacheService.readJson('map_snapshot_null_null');
      final markers = baseCachedJson != null ? MapSnapshot.fromJson(baseCachedJson).markers : <MapMarkerData>[];
      
      var filtered = markers;
      if (dateRange != null) {
        filtered = filtered.where((m) {
          if (m.observedAt == null) return false;
          final isAfter = m.observedAt!.isAfter(dateRange.from) || m.observedAt!.isAtSameMomentAs(dateRange.from);
          final isBefore = m.observedAt!.isBefore(dateRange.to) || m.observedAt!.isAtSameMomentAs(dateRange.to);
          return isAfter && isBefore;
        }).toList();
      }
      if (source != 'all') {
         filtered = filtered.where((m) {
           return m.resolvedSourceType == source;
         }).toList();
      }
      
      final speciesMap = <String, SpeciesRankingItem>{};
      for (final m in filtered) {
        final sName = m.title.isEmpty == false ? m.title : 'Desconocida';
        final sGroup = m.groupName?.isEmpty == false ? m.groupName! : 'Sin grupo';
        
        if (!speciesMap.containsKey(sName)) {
          speciesMap[sName] = SpeciesRankingItem(speciesId: 0, scientificName: sName, taxonomicGroup: sGroup, views: 0);
        }
        final existing = speciesMap[sName]!;
        speciesMap[sName] = SpeciesRankingItem(
          speciesId: existing.speciesId,
          scientificName: existing.scientificName,
          taxonomicGroup: existing.taxonomicGroup,
          views: existing.views + 1,
        );
      }
      final sorted = speciesMap.values.toList()..sort((a, b) => b.views.compareTo(a.views));
      return sorted.take(limit).toList();
    }
  }
}
