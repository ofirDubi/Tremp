import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/station.dart';
import '../models/arrival.dart';
import '../services/api_service.dart';

/// Provider for stations browser functionality
class StationsBrowserProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Station> _stations = [];
  List<Station> _recentStations = [];
  Station? _selectedStation;
  List<Arrival> _arrivals = [];
  bool _isLoading = false;
  bool _isArrivalsLoading = false;
  String? _error;
  String? _arrivalsError;
  String _searchQuery = '';
  Timer? _debounceTimer;

  static const String _recentStationsKey = 'recent_stations';
  static const int _maxRecentStations = 10;

  StationsBrowserProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _loadRecentStations();
    loadStations();
  }

  /// All loaded stations
  List<Station> get stations => _stations;

  /// Recent stations
  List<Station> get recentStations => _recentStations;

  /// Currently selected station
  Station? get selectedStation => _selectedStation;

  /// Arrivals for selected station
  List<Arrival> get arrivals => _arrivals;

  /// Whether stations are being loaded
  bool get isLoading => _isLoading;

  /// Whether arrivals are being loaded
  bool get isArrivalsLoading => _isArrivalsLoading;

  /// Error message if loading failed
  String? get error => _error;

  /// Error message if arrivals loading failed
  String? get arrivalsError => _arrivalsError;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Load stations from API
  Future<void> loadStations({String? query}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stations = await _apiService.searchStations(query: query);
      _stations = stations;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search stations with debounce
  void searchStations(String query) {
    _searchQuery = query;
    notifyListeners();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadStations(query: query.isEmpty ? null : query);
    });
  }

  /// Select a station and load its arrivals
  Future<void> selectStation(Station station) async {
    _selectedStation = station;
    _arrivals = [];
    _arrivalsError = null;
    notifyListeners();

    // Add to recent stations
    _addToRecentStations(station);

    // Load arrivals
    await loadArrivals(station.id);
  }

  /// Load arrivals for a station
  Future<void> loadArrivals(String stationId) async {
    _isArrivalsLoading = true;
    _arrivalsError = null;
    notifyListeners();

    try {
      final arrivals = await _apiService.getArrivals(stationId: stationId);
      _arrivals = arrivals;
      _arrivalsError = null;
    } catch (e) {
      _arrivalsError = e.toString();
      debugPrint('Error loading arrivals: $e');
    } finally {
      _isArrivalsLoading = false;
      notifyListeners();
    }
  }

  /// Clear the selected station
  void clearSelectedStation() {
    _selectedStation = null;
    _arrivals = [];
    _arrivalsError = null;
    notifyListeners();
  }

  /// Add a station to recent stations
  void _addToRecentStations(Station station) {
    // Remove if already in list
    _recentStations.removeWhere((s) => s.id == station.id);

    // Add to front
    _recentStations.insert(0, station);

    // Trim to max size
    if (_recentStations.length > _maxRecentStations) {
      _recentStations = _recentStations.sublist(0, _maxRecentStations);
    }

    // Save to prefs
    _saveRecentStations();
  }

  /// Load recent stations from shared preferences
  Future<void> _loadRecentStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recentStationsKey);
      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _recentStations = list
            .map((e) => Station.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading recent stations: $e');
    }
  }

  /// Save recent stations to shared preferences
  Future<void> _saveRecentStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_recentStations.map((s) => s.toJson()).toList());
      await prefs.setString(_recentStationsKey, json);
    } catch (e) {
      debugPrint('Error saving recent stations: $e');
    }
  }

  /// Clear recent stations
  Future<void> clearRecentStations() async {
    _recentStations.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentStationsKey);
    } catch (e) {
      debugPrint('Error clearing recent stations: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
