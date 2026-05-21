import 'package:latlong2/latlong.dart';

import 'observation.dart';

class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.position,
    required this.title,
    this.subtitle,
    this.imageUrl,
  });

  final String id;
  final LatLng position;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  factory MapMarkerData.fromObservation(Observation observation) {
    return MapMarkerData(
      id: observation.id,
      position: LatLng(observation.latitude ?? 0, observation.longitude ?? 0),
      title: observation.speciesName ?? 'Observación',
      subtitle: observation.observerName,
      imageUrl: observation.imageUrl,
    );
  }
}

class MapSnapshot {
  const MapSnapshot({
    required this.markers,
    this.center,
    this.zoom,
  });

  final List<MapMarkerData> markers;
  final LatLng? center;
  final double? zoom;

  factory MapSnapshot.fromObservations(List<Observation> observations) {
    final markers = observations
        .where((observation) => observation.hasCoordinates)
        .map(MapMarkerData.fromObservation)
        .toList();

    final center = markers.isNotEmpty ? markers.first.position : const LatLng(4.5709, -74.2973);
    return MapSnapshot(markers: markers, center: center, zoom: markers.isNotEmpty ? 5.0 : 4.0);
  }

  factory MapSnapshot.fromJson(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final items = payload['markers'] ?? payload['items'] ?? payload['data'];
      if (items is List) {
        final markerItems = items.whereType<Map>().map((item) {
          final data = Map<String, dynamic>.from(item);
          final lat = (data['latitude'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble() ?? 0;
          final lng = (data['longitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble() ?? 0;
          return MapMarkerData(
            id: data['id']?.toString() ?? '',
            position: LatLng(lat, lng),
            title: data['title']?.toString() ?? data['name']?.toString() ?? 'Punto de mapa',
            subtitle: data['subtitle']?.toString() ?? data['description']?.toString(),
            imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(),
          );
        }).toList();

        final centerPayload = payload['center'];
        LatLng? center;
        if (centerPayload is Map) {
          final centerMap = Map<String, dynamic>.from(centerPayload);
          final lat = (centerMap['latitude'] as num?)?.toDouble() ?? (centerMap['lat'] as num?)?.toDouble();
          final lng = (centerMap['longitude'] as num?)?.toDouble() ?? (centerMap['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            center = LatLng(lat, lng);
          }
        }

        final zoom = (payload['zoom'] as num?)?.toDouble();
        return MapSnapshot(
          markers: markerItems,
          center: center ?? (markerItems.isNotEmpty ? markerItems.first.position : const LatLng(4.5709, -74.2973)),
          zoom: zoom,
        );
      }
    }

    return const MapSnapshot(markers: []);
  }
}