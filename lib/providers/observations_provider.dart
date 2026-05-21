import 'package:flutter/foundation.dart';

import '../models/observation.dart';
import '../repositories/observations_repository.dart';

class ObservationsProvider extends ChangeNotifier {
  ObservationsProvider({required this.repository});

  final ObservationsRepository repository;

  List<Observation> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  List<Observation> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> loadObservations({bool refresh = false, String? query}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await repository.loadObservations(refresh: refresh, query: query);
      _lastSyncedAt = DateTime.now();
    } catch (error) {
      _errorMessage = error.toString();
      final cachedItems = await repository.loadCachedObservations(query: query);
      if (cachedItems.isNotEmpty) {
        _items = cachedItems;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({String? query}) => loadObservations(refresh: true, query: query);
}