import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/arrival.dart';
import '../models/station.dart';
import '../providers/station_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Bottom sheet showing station info with real-time arrivals
class StationInfoSheet extends StatelessWidget {
  final Station station;
  final VoidCallback onClose;

  const StationInfoSheet({
    super.key,
    required this.station,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Station header
            _buildHeader(context),

            // Serving lines
            if (station.lines.isNotEmpty) _buildServingLines(),

            const Divider(color: AppColors.divider, height: 24),

            // Arrivals section
            _buildArrivalsSection(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Station icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.stationMarkerYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus,
              color: Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // Station name and ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.displayName,
                  style: AppTextStyles.headline3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'תחנה ${station.id}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildServingLines() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'קווים עוברים:',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: station.lines.map((line) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: line.displayColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: line.displayColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  line.number,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: line.displayColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalsSection() {
    return Consumer<StationProvider>(
      builder: (context, provider, child) {
        if (provider.arrivalsLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            ),
          );
        }

        if (provider.arrivalsError != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.errorRed,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'שגיאה בטעינת הגעות',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.arrivals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColors.textTertiary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'אין הגעות קרובות',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'הגעות קרובות',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    color: AppColors.textTertiary,
                    onPressed: () {
                      provider.loadArrivalsForStation(station.id);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Show up to 5 arrivals
            ...provider.arrivals.take(5).map((arrival) {
              return _ArrivalRow(arrival: arrival);
            }),
          ],
        );
      },
    );
  }
}

/// A row showing a single arrival
class _ArrivalRow extends StatelessWidget {
  final Arrival arrival;

  const _ArrivalRow({required this.arrival});

  @override
  Widget build(BuildContext context) {
    final minutes = arrival.getMinutesUntil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Line badge
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: arrival.line.displayColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: arrival.line.displayColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                arrival.line.number,
                style: AppTextStyles.lineNumber.copyWith(
                  color: arrival.line.displayColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Destination
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
                if (arrival.isRealtime)
                  Row(
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
              ],
            ),
          ),

          // Time until arrival
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMinutes(minutes),
                style: AppTextStyles.arrivalMinutes.copyWith(
                  color: minutes <= 3
                      ? AppColors.warningOrange
                      : AppColors.primaryBlue,
                ),
              ),
              Text(
                minutes == 1 ? 'דקה' : 'דקות',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return 'עכשיו';
    return minutes.toString();
  }
}
