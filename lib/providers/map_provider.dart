import 'package:flutter/foundation.dart';

import '../models/map_snapshot.dart';
import '../providers/filter_provider.dart';
import '../repositories/map_repository.dart';

class MapProvider extends ChangeNotifier {
  MapProvider({required this.repository});

  final MapRepository repository;

  MapSnapshot? _snapshot;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  MapSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> loadSnapshot({
    bool refresh = false,
    DateRangeFilter? dateRange,
  }) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshot = await repository.loadMapSnapshot(
        refresh: refresh,
        dateRange: dateRange,
      );
      _lastSyncedAt = DateTime.now();
    } catch (error) {
      _errorMessage = error.toString();
      _snapshot = await repository.loadCachedSnapshot();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({DateRangeFilter? dateRange}) =>
      loadSnapshot(refresh: true, dateRange: dateRange);
}