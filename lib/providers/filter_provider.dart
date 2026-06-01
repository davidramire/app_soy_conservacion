import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DateRangeFilter {
  const DateRangeFilter({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  Map<String, String> toQueryParams() {
    return {
      'dateFrom': _formatDate(from),
      'dateTo': _formatDate(to),
    };
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class FilterProvider extends ChangeNotifier {
  FilterProvider(this._preferences) {
    _loadFromStorage();
  }

  static const String _rangeFromKey = 'filter_date_from';
  static const String _rangeToKey = 'filter_date_to';
  static const String _yearModeKey = 'filter_year_mode';
  static const String _selectedYearKey = 'filter_selected_year';
  static const String _odkKey = 'filter_source_odk';
  static const String _inatKey = 'filter_source_inaturalist';

  final SharedPreferences _preferences;

  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isYearMode = false;
  int? _selectedYear;
  bool _includeOdk = true;
  bool _includeInaturalist = true;
  DateTime? _minBound;
  DateTime? _maxBound;

  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool get isYearMode => _isYearMode;
  int? get selectedYear => _selectedYear;
  bool get includeOdk => _includeOdk;
  bool get includeInaturalist => _includeInaturalist;
  DateTime? get minBound => _minBound;
  DateTime? get maxBound => _maxBound;

  bool get hasDateFilter => effectiveDateRange != null;

  DateRangeFilter? get effectiveDateRange {
    if (_isYearMode && _selectedYear != null) {
      return DateRangeFilter(
        from: DateTime(_selectedYear!, 1, 1),
        to: DateTime(_selectedYear!, 12, 31, 23, 59, 59),
      );
    }
    if (_dateFrom != null && _dateTo != null) {
      return DateRangeFilter(from: _dateFrom!, to: _dateTo!);
    }
    return null;
  }

  List<int> get availableYears {
    final minYear = (_minBound ?? DateTime.now()).year;
    final maxYear = (_maxBound ?? DateTime.now()).year;
    if (maxYear < minYear) {
      return [DateTime.now().year];
    }
    return List.generate(maxYear - minYear + 1, (index) => maxYear - index);
  }

  void _loadFromStorage() {
    final fromMillis = _preferences.getInt(_rangeFromKey);
    final toMillis = _preferences.getInt(_rangeToKey);
    _dateFrom = fromMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(fromMillis);
    _dateTo = toMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(toMillis);
    _isYearMode = _preferences.getBool(_yearModeKey) ?? false;
    _selectedYear = _preferences.getInt(_selectedYearKey);
    _includeOdk = _preferences.getBool(_odkKey) ?? true;
    _includeInaturalist = _preferences.getBool(_inatKey) ?? true;
  }

  Future<void> _persist() async {
    if (_dateFrom != null) {
      await _preferences.setInt(_rangeFromKey, _dateFrom!.millisecondsSinceEpoch);
    } else {
      await _preferences.remove(_rangeFromKey);
    }
    if (_dateTo != null) {
      await _preferences.setInt(_rangeToKey, _dateTo!.millisecondsSinceEpoch);
    } else {
      await _preferences.remove(_rangeToKey);
    }
    await _preferences.setBool(_yearModeKey, _isYearMode);
    if (_selectedYear != null) {
      await _preferences.setInt(_selectedYearKey, _selectedYear!);
    } else {
      await _preferences.remove(_selectedYearKey);
    }
    await _preferences.setBool(_odkKey, _includeOdk);
    await _preferences.setBool(_inatKey, _includeInaturalist);
  }

  void setDateBounds({DateTime? minDate, DateTime? maxDate}) {
    _minBound = minDate;
    _maxBound = maxDate ?? DateTime.now();
    if (_dateFrom == null && minDate != null) {
      _dateFrom = DateTime(minDate.year, minDate.month, minDate.day);
      _dateTo = DateTime.now();
    }
    if (_selectedYear == null && _maxBound != null) {
      _selectedYear = _maxBound!.year;
    }
    notifyListeners();
  }

  Future<void> setDateRange(DateTime from, DateTime to) async {
    _dateFrom = DateTime(from.year, from.month, from.day);
    _dateTo = DateTime(to.year, to.month, to.day, 23, 59, 59);
    _isYearMode = false;
    await _persist();
    notifyListeners();
  }

  Future<void> setYearMode(bool enabled) async {
    _isYearMode = enabled;
    if (enabled && _selectedYear == null) {
      _selectedYear = (_maxBound ?? DateTime.now()).year;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setSelectedYear(int year) async {
    _selectedYear = year;
    _isYearMode = true;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleSource({bool? odk, bool? inaturalist}) async {
    if (odk != null) {
      _includeOdk = odk;
    }
    if (inaturalist != null) {
      _includeInaturalist = inaturalist;
    }
    if (!_includeOdk && !_includeInaturalist) {
      _includeOdk = true;
      _includeInaturalist = true;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> reset() async {
    _isYearMode = false;
    _selectedYear = (_maxBound ?? DateTime.now()).year;
    if (_minBound != null) {
      _dateFrom = DateTime(_minBound!.year, _minBound!.month, _minBound!.day);
      _dateTo = DateTime.now();
    } else {
      _dateFrom = null;
      _dateTo = null;
    }
    _includeOdk = true;
    _includeInaturalist = true;
    await _persist();
    notifyListeners();
  }

  String get activeSourceQuery {
    if (_includeOdk && _includeInaturalist) {
      return 'all';
    }
    if (_includeOdk) {
      return 'odk';
    }
    return 'inaturalist';
  }
}
