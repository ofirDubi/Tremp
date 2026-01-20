import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/location.dart';
import '../../models/place.dart';
import '../../models/route.dart' show TransitRoute, RouteLeg, RouteMode;
import '../../providers/route_search_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import 'route_details_screen.dart';

/// Route Search Screen - Search for directions, lines, and stations
/// Phase 5: Implements route planning with origin/destination inputs
class RouteSearchScreen extends StatefulWidget {
  /// Optional initial destination for pre-filling
  final Place? initialDestination;

  /// Current user location for "Current Location" option
  final Location? userLocation;

  const RouteSearchScreen({
    super.key,
    this.initialDestination,
    this.userLocation,
  });

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RouteSearchProvider _provider;

  // Text controllers for search inputs
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Focus nodes
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();

  // Which field is currently active for search
  bool _isOriginActive = false;
  bool _isDestinationActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _provider = RouteSearchProvider();

    // Set initial destination if provided
    if (widget.initialDestination != null) {
      _provider.setDestination(widget.initialDestination);
      _destinationController.text = widget.initialDestination!.displayName;
    }

    // Set current location as default origin if available
    if (widget.userLocation != null) {
      final origin = Place.currentLocation(widget.userLocation!);
      _provider.setOrigin(origin);
      _originController.text = origin.displayName;
    }

    // Listen to focus changes
    _originFocus.addListener(_onOriginFocusChange);
    _destinationFocus.addListener(_onDestinationFocusChange);

    // Listen to text changes for search
    _originController.addListener(_onOriginTextChanged);
    _destinationController.addListener(_onDestinationTextChanged);
  }

  void _onOriginFocusChange() {
    setState(() {
      _isOriginActive = _originFocus.hasFocus;
      if (!_originFocus.hasFocus) {
        _provider.clearSearchResults();
      }
    });
  }

  void _onDestinationFocusChange() {
    setState(() {
      _isDestinationActive = _destinationFocus.hasFocus;
      if (!_destinationFocus.hasFocus) {
        _provider.clearSearchResults();
      }
    });
  }

  void _onOriginTextChanged() {
    if (_isOriginActive) {
      _provider.searchPlaces(
        _originController.text,
        userLocation: widget.userLocation,
      );
    }
  }

  void _onDestinationTextChanged() {
    if (_isDestinationActive) {
      _provider.searchPlaces(
        _destinationController.text,
        userLocation: widget.userLocation,
      );
    }
  }

  void _selectPlace(Place place) {
    if (_isOriginActive) {
      _provider.setOrigin(place);
      _originController.text = place.displayName;
      _originFocus.unfocus();
      // Focus destination if empty
      if (_destinationController.text.isEmpty) {
        _destinationFocus.requestFocus();
      }
    } else if (_isDestinationActive) {
      _provider.setDestination(place);
      _destinationController.text = place.displayName;
      _destinationFocus.unfocus();
    }
    _provider.clearSearchResults();
  }

  void _selectRecentDirection(RecentDirection direction) {
    _provider.setOrigin(direction.origin);
    _provider.setDestination(direction.destination);
    _originController.text = direction.origin.displayName;
    _destinationController.text = direction.destination.displayName;
    // Calculate route
    _provider.calculateRoute();
  }

  void _swapOriginDestination() {
    _provider.swapOriginDestination();
    setState(() {
      final tempText = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = tempText;
    });
  }

  void _clearOrigin() {
    _provider.setOrigin(null);
    _originController.clear();
  }

  void _clearDestination() {
    _provider.setDestination(null);
    _destinationController.clear();
  }

  void _showTimePicker() async {
    final result = await showModalBottomSheet<RouteMode>(
      context: context,
      backgroundColor: AppColors.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildTimePickerSheet(),
    );

    if (result != null) {
      _provider.setRouteMode(result);
      if (result != RouteMode.leaveNow) {
        // Show date/time picker
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          final now = DateTime.now();
          _provider.setSelectedTime(DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          ));
        }
      }
    }
  }

  Widget _buildTimePickerSheet() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'בחר זמן',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.schedule, color: AppColors.primaryBlue),
            title: const Text('יציאה עכשיו'),
            onTap: () => Navigator.pop(context, RouteMode.leaveNow),
          ),
          ListTile(
            leading: const Icon(Icons.departure_board, color: AppColors.primaryBlue),
            title: const Text('יציאה בשעה...'),
            onTap: () => Navigator.pop(context, RouteMode.departAt),
          ),
          ListTile(
            leading: const Icon(Icons.flag, color: AppColors.primaryBlue),
            title: const Text('הגעה עד...'),
            onTap: () => Navigator.pop(context, RouteMode.arriveBy),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _originFocus.removeListener(_onOriginFocusChange);
    _destinationFocus.removeListener(_onDestinationFocusChange);
    _originFocus.dispose();
    _destinationFocus.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button and origin/destination inputs
              _buildHeader(),

              // Tab bar: Directions / Lines / Stations
              _buildTabBar(),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDirectionsTab(),
                    _buildLinesTab(),
                    _buildStationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Back button row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'תכנון מסלול',
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Origin and destination inputs with swap button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route indicators (dots and line)
              _buildRouteIndicators(),

              const SizedBox(width: 12),

              // Input fields
              Expanded(
                child: Consumer<RouteSearchProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        // Origin input
                        _buildSearchInput(
                          controller: _originController,
                          focusNode: _originFocus,
                          hint: 'מאיפה?',
                          isActive: _isOriginActive,
                          onClear: provider.origin != null ? _clearOrigin : null,
                        ),

                        const SizedBox(height: 8),

                        // Destination input
                        _buildSearchInput(
                          controller: _destinationController,
                          focusNode: _destinationFocus,
                          hint: 'לאן?',
                          isActive: _isDestinationActive,
                          onClear: provider.destination != null ? _clearDestination : null,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Swap button
              IconButton(
                icon: const Icon(
                  Icons.swap_vert,
                  color: AppColors.textSecondary,
                ),
                onPressed: _swapOriginDestination,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteIndicators() {
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          const SizedBox(height: 14),
          // Origin dot (blue filled)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
          // Connecting line
          Container(
            width: 2,
            height: 32,
            color: AppColors.divider,
          ),
          // Destination dot (red outline)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.errorRed,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildSearchInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool isActive,
    VoidCallback? onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.searchBarBackground,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppColors.primaryBlue, width: 1.5)
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.searchBarHint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surfaceColor,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.activeTabBlue,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.activeTabBlue,
        indicatorWeight: 3,
        labelStyle: AppTextStyles.tabLabel,
        unselectedLabelStyle: AppTextStyles.tabLabel,
        tabs: const [
          Tab(text: 'מסלולים'),
          Tab(text: 'קווים'),
          Tab(text: 'תחנות'),
        ],
      ),
    );
  }

  Widget _buildDirectionsTab() {
    return Consumer<RouteSearchProvider>(
      builder: (context, provider, child) {
        // Show search results if searching
        if (_isOriginActive || _isDestinationActive) {
          return _buildSearchResults(provider);
        }

        // Show route results if available
        if (provider.routeResults.isNotEmpty) {
          return _buildRouteResults(provider);
        }

        return _buildDirectionsContent(provider);
      },
    );
  }

  Widget _buildDirectionsContent(RouteSearchProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time selector (Leave now)
          _buildTimeSelector(provider),

          const SizedBox(height: 24),

          // Favorites section
          _buildFavoritesSection(provider),

          const SizedBox(height: 24),

          // Recent directions section
          _buildRecentDirectionsSection(provider),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(RouteSearchProvider provider) {
    String timeText;
    switch (provider.routeMode) {
      case RouteMode.leaveNow:
        timeText = 'יציאה עכשיו';
        break;
      case RouteMode.departAt:
        timeText = provider.selectedTime != null
            ? 'יציאה ב-${provider.selectedTime!.hour.toString().padLeft(2, '0')}:${provider.selectedTime!.minute.toString().padLeft(2, '0')}'
            : 'יציאה בשעה...';
        break;
      case RouteMode.arriveBy:
        timeText = provider.selectedTime != null
            ? 'הגעה עד ${provider.selectedTime!.hour.toString().padLeft(2, '0')}:${provider.selectedTime!.minute.toString().padLeft(2, '0')}'
            : 'הגעה עד...';
        break;
    }

    return GestureDetector(
      onTap: _showTimePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              timeText,
              style: AppTextStyles.bodyMedium,
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(RouteSearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'מועדפים',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        // Favorites grid
        Row(
          children: [
            Expanded(
              child: _buildFavoriteCard(
                icon: Icons.home_outlined,
                label: 'בית',
                subtitle: provider.homeLocation?.displayName ?? 'הגדר מיקום',
                hasLocation: provider.homeLocation != null,
                onTap: () {
                  if (provider.homeLocation != null) {
                    _selectPlace(provider.homeLocation!);
                  } else {
                    // Focus destination to set home
                    _destinationFocus.requestFocus();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFavoriteCard(
                icon: Icons.work_outline,
                label: 'עבודה',
                subtitle: provider.workLocation?.displayName ?? 'הגדר מיקום',
                hasLocation: provider.workLocation != null,
                onTap: () {
                  if (provider.workLocation != null) {
                    _selectPlace(provider.workLocation!);
                  } else {
                    // Focus destination to set work
                    _destinationFocus.requestFocus();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFavoriteCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool hasLocation,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: hasLocation ? AppColors.primaryBlue : AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: hasLocation ? AppColors.textSecondary : AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDirectionsSection(RouteSearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'חיפושים אחרונים',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (provider.recentDirections.isNotEmpty)
              TextButton(
                onPressed: provider.clearRecentDirections,
                child: Text(
                  'נקה',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.recentDirections.isEmpty)
          _buildEmptyState(
            icon: Icons.history,
            message: 'אין חיפושים אחרונים',
          )
        else
          ...provider.recentDirections.map((direction) => _buildRecentDirectionCard(direction)),
      ],
    );
  }

  Widget _buildRecentDirectionCard(RecentDirection direction) {
    return GestureDetector(
      onTap: () => _selectRecentDirection(direction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history,
              color: AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    direction.origin.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    direction.destination.displayName,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(RouteSearchProvider provider) {
    if (provider.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (provider.searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'שגיאה בחיפוש',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      final searchText = _isOriginActive
          ? _originController.text
          : _destinationController.text;

      if (searchText.length < 2) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'הקלד כדי לחפש',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'לא נמצאו תוצאות',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final place = provider.searchResults[index];
        return _buildPlaceSearchResult(place);
      },
    );
  }

  Widget _buildPlaceSearchResult(Place place) {
    IconData icon;
    switch (place.type) {
      case PlaceType.station:
        icon = Icons.directions_bus;
        break;
      case PlaceType.poi:
        icon = Icons.place;
        break;
      case PlaceType.currentLocation:
        icon = Icons.my_location;
        break;
      default:
        icon = Icons.location_on;
    }

    return GestureDetector(
      onTap: () => _selectPlace(place),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.address!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteResults(RouteSearchProvider provider) {
    if (provider.isCalculatingRoute) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (provider.routeError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'שגיאה בחישוב המסלול',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: provider.clearRouteResults,
              child: const Text('נסה שוב'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.routeResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header with route summary
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'נמצאו ${provider.routeResults.length} מסלולים',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: provider.clearRouteResults,
                  child: const Text('חיפוש חדש'),
                ),
              ],
            ),
          );
        }
        final route = provider.routeResults[index - 1];
        return _buildRouteCard(route);
      },
    );
  }

  Widget _buildRouteCard(TransitRoute route) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RouteDetailsScreen(route: route),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and duration row
            Row(
              children: [
                Text(
                  route.formattedDepartureTime,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  route.formattedArrivalTime,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${route.totalDurationMinutes} דק\'',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route legs summary
            Row(
              children: [
                for (int i = 0; i < route.legs.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 16,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: AppColors.divider,
                    ),
                  _buildLegIndicator(route.legs[i]),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Transfers and walking info
            Row(
              children: [
                if (route.transfers > 0) ...[
                  const Icon(
                    Icons.swap_horiz,
                    color: AppColors.textTertiary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${route.transfers} העברות',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (route.walkingDurationMinutes != null && route.walkingDurationMinutes! > 0) ...[
                  const Icon(
                    Icons.directions_walk,
                    color: AppColors.textTertiary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${route.walkingDurationMinutes} דק\' הליכה',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegIndicator(RouteLeg leg) {
    if (leg.isWalking) {
      return const Icon(
        Icons.directions_walk,
        color: AppColors.textTertiary,
        size: 20,
      );
    }

    final color = leg.line != null
        ? Color(int.parse(leg.line!.color?.substring(1) ?? 'FF2196F3', radix: 16) | 0xFF000000)
        : AppColors.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        leg.line?.number ?? '',
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinesTab() {
    // Placeholder for Lines search
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'חיפוש קווים',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'הקלד מספר קו או יעד',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStationsTab() {
    // Placeholder for Stations search
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'חיפוש תחנות',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'הקלד שם תחנה או מספר',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
