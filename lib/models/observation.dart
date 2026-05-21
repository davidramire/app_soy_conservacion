import 'json_parsing.dart';

class Observation {
  const Observation({
    required this.id,
    this.speciesId,
    this.speciesName,
    this.observerName,
    this.notes,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.observedAt,
    this.sourceUrl,
  });

  final String id;
  final String? speciesId;
  final String? speciesName;
  final String? observerName;
  final String? notes;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? observedAt;
  final String? sourceUrl;

  factory Observation.fromJson(Map<String, dynamic> json) {
    final species = readMap(json, ['species', 'taxon']);
    final coordinates = readMap(json, ['coordinates', 'location', 'geometry']);
    return Observation(
      id: readString(json, ['id', '_id', 'uuid']) ?? '',
      speciesId: readString(json, ['speciesId', 'species_id']) ?? readString(species ?? json, ['id', '_id', 'uuid']),
      speciesName: readString(json, ['speciesName', 'species_name', 'taxonName']) ??
          readString(species ?? json, ['name', 'common_name', 'commonName', 'title']),
      observerName: readString(json, ['observerName', 'observer_name', 'userName', 'username']),
      notes: readString(json, ['notes', 'description', 'comment']),
      imageUrl: readString(json, ['imageUrl', 'image_url', 'photoUrl', 'thumbnail']),
      latitude: readDouble(json, ['latitude', 'lat']) ?? readDouble(coordinates ?? json, ['latitude', 'lat']),
      longitude: readDouble(json, ['longitude', 'lng', 'lon']) ?? readDouble(coordinates ?? json, ['longitude', 'lng', 'lon']),
      observedAt: readDateTime(json, ['observedAt', 'observed_at', 'createdAt', 'created_at']),
      sourceUrl: readString(json, ['sourceUrl', 'source_url', 'url']),
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'speciesId': speciesId,
        'speciesName': speciesName,
        'observerName': observerName,
        'notes': notes,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'observedAt': observedAt?.toIso8601String(),
        'sourceUrl': sourceUrl,
      };
}