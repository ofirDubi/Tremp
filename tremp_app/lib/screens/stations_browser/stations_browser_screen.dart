import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/station.dart';
import '../../providers/stations_browser_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/station_card.dart';
import 'station_detail_screen.dart';

/// Stations Browser Screen - Browse and search stations
/// Phase 7: Implements station browsing with search by ID/name
class StationsBrowserScreen extends StatefulWidget {
  const StationsBrowserScreen({super.key});

  @override
  State<StationsBrowserScreen> createState() => _StationsBrowserScreenState();
}

class _StationsBrowserScreenState extends State<StationsBrowserScreen> {
  late StationsBrowserProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _provider = StationsBrowserProvider();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _provider.searchStations(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
  }

  void _onStationTap(Station station) {
    // Select station and navigate to detail
    _provider.selectStation(station);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _provider,
          child: const StationDetailScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
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
              // Header with title
              _buildHeader(),

              // Search bar
              _buildSearchBar(),

              // Content: stations list or empty state
              Expanded(
                child: Consumer<StationsBrowserProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.stations.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (provider.error != null && provider.stations.isEmpty) {
                      return _buildErrorState(provider.error!);
                    }

                    return _buildContent(provider);
                  },
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'תחנות',
            style: AppTextStyles.headline2,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<StationsBrowserProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.searchBarBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'חיפוש תחנה לפי מספר או שם',
              hintStyle: AppTextStyles.searchBarHint,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textTertiary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(StationsBrowserProvider provider) {
    // Show recent stations section if no search query
    if (provider.searchQuery.isEmpty) {
      return CustomScrollView(
        slivers: [
          // Recent stations section
          if (provider.recentStations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: 'תחנות אחרונות',
                onClear: provider.clearRecentStations,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final station = provider.recentStations[index];
                  return StationCard(
                    station: station,
                    onTap: () => _onStationTap(station),
                  );
                },
                childCount: provider.recentStations.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],

          // All stations section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'כל התחנות',
            ),
          ),
          _buildStationsList(provider.stations),
        ],
      );
    }

    // Show search results
    if (provider.stations.isEmpty) {
      return _buildEmptySearchState();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            title: 'נמצאו ${provider.stations.length} תחנות',
          ),
        ),
        _buildStationsList(provider.stations),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: Text(
                'נקה',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStationsList(List<Station> stations) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final station = stations[index];
          return StationCard(
            station: station,
            onTap: () => _onStationTap(station),
          );
        },
        childCount: stations.length,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'שגיאה בטעינת תחנות',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _provider.loadStations(),
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'לא נמצאו תחנות',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'נסה לחפש לפי מספר תחנה או שם',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
