import '../core/network/api_client.dart';
import '../providers/filter_provider.dart';

class TaxonomicGroupStat {
  const TaxonomicGroupStat({required this.name, required this.total});

  final String name;
  final int total;

  factory TaxonomicGroupStat.fromJson(Map<String, dynamic> json) {
    return TaxonomicGroupStat(
      name: json['nombre']?.toString() ?? 'Sin grupo',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'total': total,
    };
  }
}

class UserRankingItem {
  const UserRankingItem({required this.username, required this.total});

  final String username;
  final int total;

  factory UserRankingItem.fromJson(Map<String, dynamic> json) {
    return UserRankingItem(
      username: json['username']?.toString() ?? 'Anónimo',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'total': total,
    };
  }
}

class SpeciesRankingItem {
  const SpeciesRankingItem({
    required this.speciesId,
    required this.scientificName,
    required this.taxonomicGroup,
    required this.views,
  });

  final int speciesId;
  final String scientificName;
  final String taxonomicGroup;
  final int views;

  factory SpeciesRankingItem.fromJson(Map<String, dynamic> json) {
    return SpeciesRankingItem(
      speciesId: (json['idEspecie'] as num?)?.toInt() ?? 0,
      scientificName: json['scientificName']?.toString() ?? 'Especie desconocida',
      taxonomicGroup: json['taxonomicGroup']?.toString() ?? 'Sin grupo',
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idEspecie': speciesId,
      'scientificName': scientificName,
      'taxonomicGroup': taxonomicGroup,
      'views': views,
    };
  }
}

class DateBounds {
  const DateBounds({this.minDate, this.maxDate});

  final DateTime? minDate;
  final DateTime? maxDate;

  factory DateBounds.fromJson(Map<String, dynamic> json) {
    return DateBounds(
      minDate: _parseDate(json['minDate']),
      maxDate: _parseDate(json['maxDate']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'minDate': minDate?.toIso8601String(),
      'maxDate': maxDate?.toIso8601String(),
    };
  }
}

class AnalyticsService {
  AnalyticsService({required this.apiClient});

  final ApiClient apiClient;

  Future<DateBounds> fetchDateBounds() async {
    final payload = await apiClient.getJson('/analytics/date-bounds');
    if (payload is Map<String, dynamic>) {
      return DateBounds.fromJson(payload);
    }
    return const DateBounds();
  }

  Future<List<TaxonomicGroupStat>> fetchTaxonomicGroups({
    DateRangeFilter? dateRange,
    String source = 'all',
  }) async {
    final payload = await apiClient.getJson(
      '/analytics/taxonomic-groups',
      queryParameters: {
        'source': source,
        ...?dateRange?.toQueryParams(),
      },
    );
    return _readList(payload, TaxonomicGroupStat.fromJson);
  }

  Future<List<UserRankingItem>> fetchUserRanking({
    DateRangeFilter? dateRange,
    String source = 'all',
    int limit = 12,
  }) async {
    final payload = await apiClient.getJson(
      '/analytics/ranking-users',
      queryParameters: {
        'source': source,
        'limit': '$limit',
        ...?dateRange?.toQueryParams(),
      },
    );
    return _readList(payload, UserRankingItem.fromJson);
  }

  Future<List<SpeciesRankingItem>> fetchSpeciesRanking({
    DateRangeFilter? dateRange,
    String source = 'all',
    int limit = 12,
  }) async {
    final payload = await apiClient.getJson(
      '/analytics/ranking-species',
      queryParameters: {
        'source': source,
        'limit': '$limit',
        ...?dateRange?.toQueryParams(),
      },
    );
    return _readList(payload, SpeciesRankingItem.fromJson);
  }

  List<T> _readList<T>(
    dynamic payload,
    T Function(Map<String, dynamic> json) mapper,
  ) {
    if (payload is! Map) {
      return const [];
    }
    final map = Map<String, dynamic>.from(payload);
    final data = map['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map>()
        .map((item) => mapper(Map<String, dynamic>.from(item)))
        .toList();
  }
}
