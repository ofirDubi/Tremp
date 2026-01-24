import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/arrival.dart';
import '../../providers/stations_browser_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/line_badge.dart';

/// Station Detail Screen - Shows real-time arrivals for a station
/// Phase 7C.3: Displays station information and arrivals
class StationDetailScreen extends StatelessWidget {
  const StationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StationsBrowserProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, provider),

                // Content
                Expanded(
                  child: _buildContent(provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, StationsBrowserProvider provider) {
    final station = provider.selectedStation;

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
          // Back button and title row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () {
                  provider.clearSelectedStation();
                  Navigator.of(context).pop();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'פרטי תחנה',
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),

          if (station != null) ...[
            const SizedBox(height: 16),

            // Station info card
            Row(
              children: [
                // Station icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.stationMarkerYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.stationMarkerYellow,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Station details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.displayName,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'תחנה ${station.id}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Line badges
            if (station.lines.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: LineBadgesRow(
                  lines: station.lines,
                  maxVisible: 8,
                  compact: false,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContent(StationsBrowserProvider provider) {
    if (provider.isArrivalsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (provider.arrivalsError != null) {
      return _buildErrorState(provider.arrivalsError!, provider);
    }

    final station = provider.selectedStation;
    if (station == null) {
      return _buildEmptyState();
    }

    if (provider.arrivals.isEmpty) {
      return _buildNoArrivalsState();
    }

    return _buildArrivalsList(provider.arrivals);
  }

  Widget _buildArrivalsList(List<Arrival> arrivals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'הגעות קרובות',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.realtimeGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.realtimeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'זמן אמת',
                      style: AppTextStyles.realtimeLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Arrivals list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: arrivals.length,
            itemBuilder: (context, index) {
              final arrival = arrivals[index];
              return _buildArrivalItem(arrival);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalItem(Arrival arrival) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Line badge
          LineBadge(
            line: arrival.line,
            compact: false,
          ),

          const SizedBox(width: 14),

          // Destination info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arrival.displayDestination,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Realtime indicator
                    if (arrival.isRealtime)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.realtimeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      arrival.formattedTime,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Minutes until arrival
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: arrival.isRealtime
                  ? AppColors.primaryBlue.withOpacity(0.15)
                  : AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${arrival.getMinutesUntil()}',
                  style: AppTextStyles.arrivalMinutes.copyWith(
                    color: arrival.isRealtime
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'דק\'',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: arrival.isRealtime
                        ? AppColors.primaryBlue
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, StationsBrowserProvider provider) {
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
              'שגיאה בטעינת הגעות',
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
              onPressed: () {
                if (provider.selectedStation != null) {
                  provider.loadArrivals(provider.selectedStation!.id);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'לא נבחרה תחנה',
            style: AppTextStyles.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNoArrivalsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'אין הגעות קרובות',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'לא נמצא מידע על הגעות עבור תחנה זו',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
