import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/location.dart';
import '../models/place.dart';
import '../models/route.dart';
import '../services/api_service.dart';

/// Provider for managing route search state
class RouteSearchProvider extends ChangeNotifier {
  final ApiService _apiService;

  // Search state
  List<Place> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  // Route calculation state
  List<TransitRoute> _routeResults = [];
  bool _isCalculatingRoute = false;
  String? _routeError;

  // Origin and destination
  Place? _origin;
  Place? _destination;

  // Time selection
  RouteMode _routeMode = RouteMode.leaveNow;
  DateTime? _selectedTime;

  // Recent directions
  List<RecentDirection> _recentDirections = [];

  // Favorites
  Place? _homeLocation;
  Place? _workLocation;
  List<Place> _customFavorites = [];

  // Debounce timer for search
  Timer? _debounceTimer;

  RouteSearchProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.mock() {
    _loadSavedData();
  }

  // Getters
  List<Place> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  List<TransitRoute> get routeResults => _routeResults;
  bool get isCalculatingRoute => _isCalculatingRoute;
  String? get routeError => _routeError;

  Place? get origin => _origin;
  Place? get destination => _destination;

  RouteMode get routeMode => _routeMode;
  DateTime? get selectedTime => _selectedTime;

  List<RecentDirection> get recentDirections => _recentDirections;

  Place? get homeLocation => _homeLocation;
  Place? get workLocation => _workLocation;
  List<Place> get customFavorites => _customFavorites;

  /// Set origin location
  void setOrigin(Place? place) {
    _origin = place;
    notifyListeners();
  }

  /// Set destination location
  void setDestination(Place? place) {
    _destination = place;
    notifyListeners();
  }

  /// Swap origin and destination
  void swapOriginDestination() {
    final temp = _origin;
    _origin = _destination;
    _destination = temp;
    notifyListeners();
  }

  /// Set route mode
  void setRouteMode(RouteMode mode) {
    _routeMode = mode;
    notifyListeners();
  }

  /// Set selected time for depart_at or arrive_by modes
  void setSelectedTime(DateTime? time) {
    _selectedTime = time;
    notifyListeners();
  }

  /// Search for places with debouncing
  void searchPlaces(String query, {Location? userLocation}) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Clear results if query is too short
    if (query.length < 2) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    // Debounce: wait 300ms before making API call
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _isSearching = true;
      _searchError = null;
      notifyListeners();

      try {
        _searchResults = await _apiService.searchPlaces(
          query: query,
          lat: userLocation?.lat,
          lon: userLocation?.lon,
        );
        _searchError = null;
      } catch (e) {
        _searchError = e.toString();
        _searchResults = [];
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  /// Calculate route between origin and destination
  Future<void> calculateRoute() async {
    if (_origin == null || _destination == null) {
      _routeError = 'Please select origin and destination';
      notifyListeners();
      return;
    }

    _isCalculatingRoute = true;
    _routeError = null;
    notifyListeners();

    try {
      _routeResults = await _apiService.calculateRoute(
        origin: _origin!.location,
        destination: _destination!.location,
        mode: _routeMode,
        departureTime: _routeMode == RouteMode.departAt ? _selectedTime : null,
        arrivalTime: _routeMode == RouteMode.arriveBy ? _selectedTime : null,
      );

      // Save to recent directions
      if (_routeResults.isNotEmpty) {
        _addRecentDirection(RecentDirection(
          origin: _origin!,
          destination: _destination!,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _routeError = e.toString();
      _routeResults = [];
    } finally {
      _isCalculatingRoute = false;
      notifyListeners();
    }
  }

  /// Clear route results
  void clearRouteResults() {
    _routeResults = [];
    _routeError = null;
    notifyListeners();
  }

  /// Add a recent direction
  void _addRecentDirection(RecentDirection direction) {
    // Remove if already exists (to move to top)
    _recentDirections.removeWhere(
      (d) =>
          d.origin.name == direction.origin.name &&
          d.destination.name == direction.destination.name,
    );

    // Add to top
    _recentDirections.insert(0, direction);

    // Keep only last 10
    if (_recentDirections.length > 10) {
      _recentDirections = _recentDirections.take(10).toList();
    }

    _saveRecentDirections();
    notifyListeners();
  }

  /// Clear recent directions
  void clearRecentDirections() {
    _recentDirections = [];
    _saveRecentDirections();
    notifyListeners();
  }

  /// Set home location
  Future<void> setHomeLocation(Place place) async {
    _homeLocation = place;
    await _saveFavorites();
    notifyListeners();
  }

  /// Set work location
  Future<void> setWorkLocation(Place place) async {
    _workLocation = place;
    await _saveFavorites();
    notifyListeners();
  }

  /// Add custom favorite
  Future<void> addCustomFavorite(Place place) async {
    if (!_customFavorites.any((f) => f.id == place.id)) {
      _customFavorites.add(place);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Remove custom favorite
  Future<void> removeCustomFavorite(String placeId) async {
    _customFavorites.removeWhere((f) => f.id == placeId);
    await _saveFavorites();
    notifyListeners();
  }

  /// Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load recent directions
    final recentJson = prefs.getString('recent_directions');
    if (recentJson != null) {
      try {
        final recentList = json.decode(recentJson) as List<dynamic>;
        _recentDirections = recentList
            .map((e) => RecentDirection.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _recentDirections = [];
      }
    }

    // Load favorites
    final homeJson = prefs.getString('home_location');
    if (homeJson != null) {
      try {
        _homeLocation = Place.fromJson(json.decode(homeJson));
      } catch (e) {
        _homeLocation = null;
      }
    }

    final workJson = prefs.getString('work_location');
    if (workJson != null) {
      try {
        _workLocation = Place.fromJson(json.decode(workJson));
      } catch (e) {
        _workLocation = null;
      }
    }

    final favoritesJson = prefs.getString('custom_favorites');
    if (favoritesJson != null) {
      try {
        final favoritesList = json.decode(favoritesJson) as List<dynamic>;
        _customFavorites = favoritesList
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _customFavorites = [];
      }
    }

    notifyListeners();
  }

  /// Save recent directions
  Future<void> _saveRecentDirections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'recent_directions',
      json.encode(_recentDirections.map((e) => e.toJson()).toList()),
    );
  }

  /// Save favorites
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    if (_homeLocation != null) {
      await prefs.setString('home_location', json.encode(_homeLocation!.toJson()));
    } else {
      await prefs.remove('home_location');
    }

    if (_workLocation != null) {
      await prefs.setString('work_location', json.encode(_workLocation!.toJson()));
    } else {
      await prefs.remove('work_location');
    }

    await prefs.setString(
      'custom_favorites',
      json.encode(_customFavorites.map((e) => e.toJson()).toList()),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// A recent direction search
class RecentDirection {
  final Place origin;
  final Place destination;
  final DateTime timestamp;

  const RecentDirection({
    required this.origin,
    required this.destination,
    required this.timestamp,
  });

  factory RecentDirection.fromJson(Map<String, dynamic> json) {
    return RecentDirection(
      origin: Place.fromJson(json['origin'] as Map<String, dynamic>),
      destination: Place.fromJson(json['destination'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
