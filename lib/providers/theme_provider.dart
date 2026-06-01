import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences) {
    _isDarkMode = _preferences.getBool(_storageKey) ?? false;
  }

  static const String _storageKey = 'theme_dark_mode';

  final SharedPreferences _preferences;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) {
      return;
    }
    _isDarkMode = value;
    await _preferences.setBool(_storageKey, value);
    notifyListeners();
  }

  Future<void> toggle() => setDarkMode(!_isDarkMode);
}
