import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/station.dart';
import '../services/api_service.dart';

/// Provider for managing station data and selection state
class StationProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Station> _stations = [];
  Station? _selectedStation;
  bool _isLoading = false;
  String? _error;

  // Track the last loaded bounds to avoid redundant requests
  MapCamera? _lastLoadedBounds;

  StationProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.mock();

  /// All loaded stations
  List<Station> get stations => _stations;

  /// Currently selected station (for bottom sheet display)
  Station? get selectedStation => _selectedStation;

  /// Whether stations are being loaded
  bool get isLoading => _isLoading;

  /// Error message if loading failed
  String? get error => _error;

  /// Load stations within the visible map bounds
  Future<void> loadStationsForBounds(MapCamera camera) async {
    // Check if we need to reload (bounds changed significantly)
    if (_lastLoadedBounds != null && !_shouldReload(camera)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bounds = camera.visibleBounds;
      final stations = await _apiService.getStations(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLon: bounds.west,
        maxLon: bounds.east,
        limit: 100,
      );

      _stations = stations;
      _lastLoadedBounds = camera;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if we should reload based on camera changes
  bool _shouldReload(MapCamera camera) {
    if (_lastLoadedBounds == null) return true;

    // Reload if zoom changed by more than 0.5
    final zoomDiff = (camera.zoom - _lastLoadedBounds!.zoom).abs();
    if (zoomDiff > 0.5) return true;

    // Reload if center moved significantly relative to visible area
    final bounds = camera.visibleBounds;
    // Note: lastBounds used implicitly for comparison via _lastLoadedBounds

    final latRange = bounds.north - bounds.south;
    final lonRange = bounds.east - bounds.west;

    final centerLatDiff =
        (camera.center.latitude - _lastLoadedBounds!.center.latitude).abs();
    final centerLonDiff =
        (camera.center.longitude - _lastLoadedBounds!.center.longitude).abs();

    // Reload if moved more than 30% of the visible range
    if (centerLatDiff > latRange * 0.3 || centerLonDiff > lonRange * 0.3) {
      return true;
    }

    return false;
  }

  /// Select a station (for displaying in bottom sheet)
  void selectStation(Station? station) {
    if (_selectedStation != station) {
      _selectedStation = station;
      notifyListeners();
    }
  }

  /// Clear the selected station
  void clearSelection() {
    if (_selectedStation != null) {
      _selectedStation = null;
      notifyListeners();
    }
  }

  /// Force refresh stations
  Future<void> refresh(MapCamera camera) async {
    _lastLoadedBounds = null;
    await loadStationsForBounds(camera);
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
