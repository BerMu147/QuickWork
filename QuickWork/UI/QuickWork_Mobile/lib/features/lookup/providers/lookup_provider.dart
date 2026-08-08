import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/lookup_repository.dart';
import '../models/city_model.dart';
import '../models/gender_model.dart';

/// Loads and caches reference data (genders, cities) for the app.
class LookupProvider extends ChangeNotifier {
  LookupProvider({LookupRepository? repository})
      : _repository = repository ?? LookupRepository();

  final LookupRepository _repository;

  List<GenderModel> _genders = [];
  List<CityModel> _cities = [];
  bool _isLoading = false;
  String? _error;

  List<GenderModel> get genders => _genders;
  List<CityModel> get cities => _cities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads genders and cities in parallel (used before showing the
  /// registration form so its dropdowns are populated).
  Future<void> loadLookups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchGenders(),
        _repository.fetchCities(),
      ]);

      _genders = results[0] as List<GenderModel>;
      _cities = results[1] as List<CityModel>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unable to load required data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the city name for a given id, or an empty string.
  String cityNameById(int id) {
    for (final c in _cities) {
      if (c.id == id) return c.name;
    }
    return '';
  }
}
