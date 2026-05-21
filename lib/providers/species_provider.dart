import 'package:flutter/foundation.dart';

import '../models/species.dart';
import '../repositories/species_repository.dart';

class SpeciesProvider extends ChangeNotifier {
  SpeciesProvider({required this.repository});

  final SpeciesRepository repository;

  List<Species> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  List<Species> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> loadSpecies({bool refresh = false, String? query}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await repository.loadSpecies(refresh: refresh, query: query);
      _lastSyncedAt = DateTime.now();
    } catch (error) {
      _errorMessage = error.toString();
      final cachedItems = await repository.loadCachedSpecies(query: query);
      if (cachedItems.isNotEmpty) {
        _items = cachedItems;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({String? query}) => loadSpecies(refresh: true, query: query);
}