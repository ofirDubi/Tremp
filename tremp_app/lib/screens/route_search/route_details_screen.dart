import 'package:flutter/material.dart';

import '../../models/route.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Route Details Screen - Shows detailed information about a transit route
class RouteDetailsScreen extends StatelessWidget {
  final TransitRoute route;

  const RouteDetailsScreen({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('פרטי מסלול'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Route legs timeline
            _buildLegsTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Time row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'יציאה',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route.formattedDepartureTime,
                    style: AppTextStyles.headline2,
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.5),
                              AppColors.errorRed,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
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
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'הגעה',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route.formattedArrivalTime,
                    style: AppTextStyles.headline2,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.swap_horiz,
                label: 'העברות',
                value: '${route.transfers}',
              ),
              if (route.walkingDurationMinutes != null &&
                  route.walkingDurationMinutes! > 0)
                _buildStatItem(
                  icon: Icons.directions_walk,
                  label: 'הליכה',
                  value: '${route.walkingDurationMinutes} דק\'',
                ),
              _buildStatItem(
                icon: Icons.directions_bus,
                label: 'תחנות',
                value: '${_totalStops}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int get _totalStops {
    return route.legs
        .where((leg) => leg.isTransit)
        .fold(0, (sum, leg) => sum + (leg.stopsCount ?? 0));
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryBlue,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium,
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegsTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פירוט המסלול',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...route.legs.asMap().entries.map((entry) {
          final index = entry.key;
          final leg = entry.value;
          final isLast = index == route.legs.length - 1;
          return _buildLegItem(leg, isLast);
        }),
      ],
    );
  }

  Widget _buildLegItem(RouteLeg leg, bool isLast) {
    if (leg.isWalking) {
      return _buildWalkingLeg(leg, isLast);
    }
    return _buildTransitLeg(leg, isLast);
  }

  Widget _buildWalkingLeg(RouteLeg leg, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textTertiary,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.directions_walk,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: AppColors.divider,
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'הליכה',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${leg.durationMinutes} דק\' • ${leg.distanceMeters ?? 0} מ\'',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'מ-${leg.from.displayName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  'אל-${leg.to.displayName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransitLeg(RouteLeg leg, bool isLast) {
    final lineColor = leg.line != null
        ? Color(int.parse(
                leg.line!.color?.substring(1) ?? 'FF2196F3',
                radix: 16) |
            0xFF000000)
        : AppColors.primaryBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  leg.line?.number ?? '',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 4,
                  height: 100,
                  decoration: BoxDecoration(
                    color: lineColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: lineColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line info row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'קו ${leg.line?.number ?? ''}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: lineColor,
                        ),
                      ),
                    ),
                    Text(
                      '${leg.durationMinutes} דק\'',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Departure
                Row(
                  children: [
                    Text(
                      _formatTime(leg.departureTime),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leg.from.displayName,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Stops indicator
                if (leg.stopsCount != null && leg.stopsCount! > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 1,
                          color: AppColors.divider,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${leg.stopsCount} תחנות',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.divider,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Arrival
                Row(
                  children: [
                    Text(
                      _formatTime(leg.arrivalTime),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leg.to.displayName,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
