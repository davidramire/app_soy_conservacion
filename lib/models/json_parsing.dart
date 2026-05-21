double? readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
  }
  return null;
}

int? readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
  }
  return null;
}

String? readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is String) {
      if (value.trim().isNotEmpty) {
        return value;
      }
    } else {
      return value.toString();
    }
  }
  return null;
}

DateTime? readDateTime(Map<String, dynamic> json, List<String> keys) {
  final value = readString(json, keys);
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}

Map<String, dynamic>? readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return null;
}