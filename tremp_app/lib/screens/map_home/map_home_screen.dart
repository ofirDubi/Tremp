import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Map Home Screen - Main map with station discovery
/// Phase 4A: Basic Map with dark tiles, user location, and zoom controls
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
    setState(() {
      _userLocation = _defaultCenter;
      _locationLoading = false;
    });
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
            bottom: 120,
            child: _buildZoomControls(),
          ),

          // Center on user button
          Positioned(
            right: 16,
            bottom: 60,
            child: _buildLocationButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        backgroundColor: AppColors.scaffoldBackground,
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

        // User location marker layer
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              _buildUserLocationMarker(_userLocation!),
            ],
          ),

        // TODO: Phase 4B - Station markers layer will be added here
      ],
    );
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
