import 'json_parsing.dart';

class Species {
  const Species({
    required this.id,
    required this.name,
    this.scientificName,
    this.kingdom,
    this.category,
    this.description,
    this.imageUrl,
    this.sourceUrl,
  });

  final String id;
  final String name;
  final String? scientificName;
  final String? kingdom;
  final String? category;
  final String? description;
  final String? imageUrl;
  final String? sourceUrl;

  factory Species.fromJson(Map<String, dynamic> json) {
    final taxon = readMap(json, ['taxon', 'species']);
    return Species(
      id: readString(json, ['id', '_id', 'uuid']) ?? readString(taxon ?? json, ['id', '_id', 'uuid']) ?? '',
      name: readString(json, ['name', 'common_name', 'commonName', 'title']) ??
          readString(taxon ?? json, ['name', 'common_name', 'commonName', 'title']) ??
          'Sin nombre',
      scientificName: readString(json, ['scientificName', 'scientific_name']) ??
          readString(taxon ?? json, ['scientificName', 'scientific_name']),
      kingdom: readString(json, ['kingdom']) ?? readString(taxon ?? json, ['kingdom']),
      category: readString(json, ['category', 'type', 'group']),
      description: readString(json, ['description', 'summary', 'notes']),
      imageUrl: readString(json, ['imageUrl', 'image_url', 'photoUrl', 'thumbnail']) ??
          readString(taxon ?? json, ['imageUrl', 'image_url', 'photoUrl', 'thumbnail']),
      sourceUrl: readString(json, ['sourceUrl', 'source_url', 'url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scientificName': scientificName,
        'kingdom': kingdom,
        'category': category,
        'description': description,
        'imageUrl': imageUrl,
        'sourceUrl': sourceUrl,
      };
}