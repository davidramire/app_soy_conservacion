import '../models/map_snapshot.dart';
import '../providers/filter_provider.dart';

bool markerMatchesDateFilter(MapMarkerData marker, FilterProvider filters) {
  final range = filters.effectiveDateRange;
  if (range == null) {
    return true;
  }

  final observedAt = marker.observedAt;
  if (observedAt == null) {
    return false;
  }

  final start = DateTime(range.from.year, range.from.month, range.from.day);
  final end = DateTime(
    range.to.year,
    range.to.month,
    range.to.day,
    23,
    59,
    59,
    999,
  );

  return !observedAt.isBefore(start) && !observedAt.isAfter(end);
}

bool markerMatchesSourceFilter(MapMarkerData marker, FilterProvider filters) {
  final source = marker.resolvedSourceType;
  if (source == 'inaturalist') {
    return filters.includeInaturalist;
  }
  return filters.includeOdk;
}

List<MapMarkerData> applyMapFilters(
  List<MapMarkerData> markers,
  FilterProvider filters,
) {
  return markers
      .where((marker) => markerMatchesDateFilter(marker, filters))
      .where((marker) => markerMatchesSourceFilter(marker, filters))
      .toList();
}
