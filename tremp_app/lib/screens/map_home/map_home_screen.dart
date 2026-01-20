import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/station.dart';
import '../../providers/station_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/bottom_sheet_container.dart';
import '../../widgets/favorites_tab.dart';
import '../../widgets/nearby_routes_tab.dart';
import '../../widgets/station_info_sheet.dart';
import '../../widgets/station_marker.dart';

/// Map Home Screen - Main map with station discovery
/// Phase 4A: Basic Map with dark tiles, user location, and zoom controls
/// Phase 4B: Station markers from API with tap handling
/// Phase 4C: Bottom sheet with Nearby Routes and Favorites tabs
class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  // Map controller for programmatic control
  final MapController _mapController = MapController();

  // Tel Aviv center as default location (Israel)
  static const LatLng _defaultCenter = LatLng(32.0853, 34.7818);
  static const double _defaultZoom = 14.0;
  static const double _minZoom = 10.0;
  static const double _maxZoom = 18.0;

  // User location (simulated for now - will be replaced with actual location)
  LatLng? _userLocation;
  bool _locationLoading = false;

  // Track if initial stations have been loaded
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    // Simulate getting user location
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _locationLoading = true;
    });

    // Simulate location fetch delay
    await Future.delayed(const Duration(milliseconds: 500));

    // For now, use Tel Aviv center as simulated user location
    // TODO: Replace with actual geolocation using geolocator package
    if (!mounted) return;

    setState(() {
      _userLocation = _defaultCenter;
      _locationLoading = false;
    });

    // Load nearby stations for the bottom sheet
    if (_userLocation != null) {
      context.read<StationProvider>().loadNearbyStations(_userLocation!);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < _maxZoom) {
      _mapController.move(
        _mapController.camera.center,
        currentZoom + 1,
      );
    }
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > _minZoom) {
      _mapController.move(
        _mapController.camera.center,
        currentZoom - 1,
      );
    }
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, _defaultZoom);
    }
  }

  void _onMapReady() {
    // Load initial stations after map is ready
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _loadStations();
    }
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    // Reload stations when map position changes significantly
    if (hasGesture) {
      _loadStations();
    }
  }

  void _loadStations() {
    final provider = context.read<StationProvider>();
    provider.loadStationsForBounds(_mapController.camera);
  }

  void _onStationTap(Station station) {
    final provider = context.read<StationProvider>();
    provider.selectStation(station);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Clear station selection when tapping on empty map area
    final provider = context.read<StationProvider>();
    provider.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map layer
          _buildMap(),

          // Search bar overlay (top)
          SafeArea(
            child: _buildSearchBar(),
          ),

          // Zoom controls (right side)
          Positioned(
            right: 16,
            bottom: 200,
            child: _buildZoomControls(),
          ),

          // Center on user button
          Positioned(
            right: 16,
            bottom: 140,
            child: _buildLocationButton(),
          ),

          // Bottom sheet layer (either selected station or nearby/favorites)
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<StationProvider>(
      builder: (context, stationProvider, child) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            backgroundColor: AppColors.scaffoldBackground,
            onMapReady: _onMapReady,
            onPositionChanged: _onMapPositionChanged,
            onTap: _onMapTap,
          ),
          children: [
            // Dark tile layer - CartoDB Dark Matter
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.tremp.app',
              retinaMode: true,
            ),

            // Station markers layer
            MarkerLayer(
              markers: _buildStationMarkers(stationProvider),
            ),

            // User location marker layer
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  _buildUserLocationMarker(_userLocation!),
                ],
              ),
          ],
        );
      },
    );
  }

  List<Marker> _buildStationMarkers(StationProvider provider) {
    return provider.stations.map((station) {
      final isSelected = provider.selectedStation?.id == station.id;
      return Marker(
        point: LatLng(station.location.lat, station.location.lon),
        width: isSelected ? 36 : 32,
        height: isSelected ? 36 : 32,
        child: SimpleStationMarker(
          station: station,
          isSelected: isSelected,
          onTap: () => _onStationTap(station),
        ),
      );
    }).toList();
  }

  Marker _buildUserLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        // TODO: Phase 5 - Navigate to route search screen
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.searchBarBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            const Text(
              'לאן נוסעים?',
              style: AppTextStyles.searchBarHint,
            ),
            const Spacer(),
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.mic_outlined,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in button
          _buildControlButton(
            icon: Icons.add,
            onTap: _zoomIn,
          ),
          Container(
            width: 32,
            height: 1,
            color: AppColors.divider,
          ),
          // Zoom out button
          _buildControlButton(
            icon: Icons.remove,
            onTap: _zoomOut,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildControlButton(
        icon: _locationLoading ? Icons.hourglass_empty : Icons.my_location,
        onTap: _centerOnUser,
        isLoading: _locationLoading,
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Consumer<StationProvider>(
      builder: (context, provider, child) {
        final station = provider.selectedStation;

        // If a station is selected, show the station info sheet
        if (station != null) {
          return Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StationInfoSheet(
              station: station,
              onClose: () => provider.clearSelection(),
            ),
          );
        }

        // Otherwise, show the nearby routes / favorites bottom sheet
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomSheetContainer(
            tabs: const [
              BottomSheetTab(
                label: 'קווים קרובים',
                icon: Icons.near_me,
                content: NearbyRoutesTab(),
              ),
              BottomSheetTab(
                label: 'מועדפים',
                icon: Icons.star_outline,
                content: FavoritesTab(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
