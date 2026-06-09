import 'package:latlong2/latlong.dart';

import 'json_parsing.dart';
import 'observation.dart';

class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.position,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.sourceUrl,
    this.sourceType,
    this.groupName,
    this.speciesId,
    this.observedAt,
  });

  final String id;
  final LatLng position;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? sourceUrl;
  final String? sourceType;
  final String? groupName;
  final String? speciesId;
  final DateTime? observedAt;

  String get resolvedSourceType {
    final normalized = sourceType?.toLowerCase() ?? sourceUrl?.toLowerCase() ?? '';
    if (normalized.contains('inaturalist')) {
      return 'inaturalist';
    }
    return 'odk';
  }

  factory MapMarkerData.fromObservation(Observation observation) {
    return MapMarkerData(
      id: observation.id,
      position: LatLng(observation.latitude ?? 0, observation.longitude ?? 0),
      title: observation.speciesName ?? 'Observación',
      subtitle: observation.observerName,
      imageUrl: observation.imageUrl,
      sourceUrl: observation.sourceUrl,
      sourceType: 'odk',
      observedAt: observation.observedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'sourceUrl': sourceUrl,
        'sourceType': sourceType,
        'groupName': groupName,
        'speciesId': speciesId,
        'observedAt': observedAt?.toIso8601String(),
      };
}

class MapSnapshot {
  const MapSnapshot({required this.markers, this.center, this.zoom});

  final List<MapMarkerData> markers;
  final LatLng? center;
  final double? zoom;

  factory MapSnapshot.fromObservations(List<Observation> observations) {
    final markers = observations
        .where((observation) => observation.hasCoordinates)
        .map(MapMarkerData.fromObservation)
        .toList();

    final center = markers.isNotEmpty
        ? markers.first.position
        : const LatLng(4.5709, -74.2973);
    return MapSnapshot(
      markers: markers,
      center: center,
      zoom: markers.isNotEmpty ? 5.0 : 4.0,
    );
  }

  factory MapSnapshot.fromJson(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final items = payload['markers'] ?? payload['items'] ?? payload['data'];
      if (items is List) {
        final markerItems = items.whereType<Map>().map((item) {
          final data = Map<String, dynamic>.from(item);
          final lat =
              (data['latitude'] as num?)?.toDouble() ??
              (data['lat'] as num?)?.toDouble() ??
              0;
          final lng =
              (data['longitude'] as num?)?.toDouble() ??
              (data['lng'] as num?)?.toDouble() ??
              0;
          return MapMarkerData(
            id: data['id']?.toString() ?? '',
            position: LatLng(lat, lng),
            title:
                data['title']?.toString() ??
                data['name']?.toString() ??
                'Punto de mapa',
            subtitle:
                data['subtitle']?.toString() ?? data['description']?.toString(),
            imageUrl:
                data['imageUrl']?.toString() ?? data['image_url']?.toString(),
            sourceUrl:
                data['sourceUrl']?.toString() ?? data['source_url']?.toString(),
            sourceType: data['sourceType']?.toString() ?? data['source_type']?.toString(),
            groupName: data['groupName']?.toString() ?? data['group_name']?.toString(),
            speciesId: data['speciesId']?.toString() ?? data['species_id']?.toString(),
            observedAt: readDateTime(data, ['observedAt', 'observed_at', 'createdAt', 'created_at']),
          );
        }).toList();

        final centerPayload = payload['center'];
        LatLng? center;
        if (centerPayload is Map) {
          final centerMap = Map<String, dynamic>.from(centerPayload);
          final lat =
              (centerMap['latitude'] as num?)?.toDouble() ??
              (centerMap['lat'] as num?)?.toDouble();
          final lng =
              (centerMap['longitude'] as num?)?.toDouble() ??
              (centerMap['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            center = LatLng(lat, lng);
          }
        }

        final zoom = (payload['zoom'] as num?)?.toDouble();
        return MapSnapshot(
          markers: markerItems,
          center:
              center ??
              (markerItems.isNotEmpty
                  ? markerItems.first.position
                  : const LatLng(4.5709, -74.2973)),
          zoom: zoom,
        );
      }
    }

    return const MapSnapshot(markers: []);
  }

  Map<String, dynamic> toJson() => {
        'markers': markers.map((m) => m.toJson()).toList(),
        'center': center != null
            ? {'latitude': center!.latitude, 'longitude': center!.longitude}
            : null,
        'zoom': zoom,
      };
}
