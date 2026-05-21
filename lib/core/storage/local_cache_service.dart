import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  const LocalCacheService();

  Future<void> saveJson(String key, Object? value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value));
  }

  Future<dynamic> readJson(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(key);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    return jsonDecode(rawValue);
  }

  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final value = await readJson(key);
    if (value is List) {
      return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return const [];
  }

  Future<void> saveString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }
}