class ApiCollection<T> {
  const ApiCollection({
    required this.items,
    this.total,
    this.page,
    this.pageSize,
    this.hasMore,
  });

  final List<T> items;
  final int? total;
  final int? page;
  final int? pageSize;
  final bool? hasMore;

  factory ApiCollection.fromJson(
    dynamic payload,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (payload == null) {
      return const ApiCollection(items: []);
    }

    if (payload is List) {
      return ApiCollection(items: payload.whereType<Map>().map((item) => fromJson(Map<String, dynamic>.from(item))).toList());
    }

    if (payload is Map<String, dynamic>) {
      final itemsPayload = _extractItems(payload);
      return ApiCollection(
        items: itemsPayload.whereType<Map>().map((item) => fromJson(Map<String, dynamic>.from(item))).toList(),
        total: _asInt(payload['total']) ?? _asInt(payload['count']),
        page: _asInt(payload['page']),
        pageSize: _asInt(payload['pageSize']) ?? _asInt(payload['limit']),
        hasMore: payload['hasMore'] as bool?,
      );
    }

    throw FormatException('Unsupported collection payload: ${payload.runtimeType}');
  }

  static List<dynamic> _extractItems(Map<String, dynamic> payload) {
    final candidates = [payload['data'], payload['items'], payload['results']];
    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate;
      }
    }

    return const [];
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}