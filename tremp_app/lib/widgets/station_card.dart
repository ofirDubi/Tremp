import 'package:flutter/material.dart';

import '../models/station.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'line_badge.dart';

/// A card displaying a station with serving line badges
class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;

  const StationCard({
    super.key,
    required this.station,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Station icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.stationMarkerYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.stationMarkerYellow,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Station info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station name
                  Text(
                    station.displayName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Station ID
                  Text(
                    'תחנה ${station.id}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),

                  // Line badges
                  if (station.lines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    LineBadgesRow(
                      lines: station.lines,
                      maxVisible: 5,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow indicator
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
