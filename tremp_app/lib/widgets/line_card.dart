import 'package:flutter/material.dart';

import '../models/line.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// A card displaying a transit line with operator info
class LineCard extends StatelessWidget {
  final Line line;
  final VoidCallback? onTap;

  const LineCard({
    super.key,
    required this.line,
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
            // Line number badge
            _buildLineBadge(),

            const SizedBox(width: 16),

            // Line info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direction
                  Text(
                    line.displayDirection,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Operator info
                  Row(
                    children: [
                      _buildOperatorIcon(),
                      const SizedBox(width: 6),
                      Text(
                        line.displayOperatorName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (line.stopsCount > 0) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        Text(
                          '${line.stopsCount} תחנות',
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

  Widget _buildLineBadge() {
    return Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        color: line.displayColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          line.number,
          style: AppTextStyles.lineNumber.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorIcon() {
    // Get operator-specific icon/color
    IconData icon;
    Color color;

    switch (line.operator.toLowerCase()) {
      case 'egged':
        icon = Icons.directions_bus;
        color = AppColors.eggedGreen;
        break;
      case 'dan':
        icon = Icons.directions_bus;
        color = AppColors.danBlue;
        break;
      case 'kavim':
        icon = Icons.directions_bus;
        color = AppColors.kavimOrange;
        break;
      case 'metropoline':
        icon = Icons.directions_bus;
        color = AppColors.metropolinePurple;
        break;
      case 'superbus':
        icon = Icons.directions_bus;
        color = AppColors.superbusRed;
        break;
      case 'israel_railways':
        icon = Icons.train;
        color = AppColors.israelRailwaysBlue;
        break;
      default:
        icon = Icons.directions_bus;
        color = AppColors.primaryBlue;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }
}
