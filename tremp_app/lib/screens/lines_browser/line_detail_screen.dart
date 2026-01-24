import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/line.dart';
import '../../providers/lines_browser_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Line Detail Screen - Shows all stops on a transit line
/// Phase 6C: Displays line information and all stops
class LineDetailScreen extends StatelessWidget {
  const LineDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LinesBrowserProvider>(
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

  Widget _buildHeader(BuildContext context, LinesBrowserProvider provider) {
    final line = provider.selectedLine;

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
                  provider.clearSelectedLine();
                  Navigator.of(context).pop();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'פרטי קו',
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),

          if (line != null) ...[
            const SizedBox(height: 16),

            // Line info card
            Row(
              children: [
                // Line number badge
                Container(
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    color: line.displayColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      line.number,
                      style: AppTextStyles.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Line details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.displayDirection,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildOperatorBadge(line),
                          const SizedBox(width: 8),
                          Text(
                            line.displayOperatorName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOperatorBadge(Line line) {
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }

  Widget _buildContent(LinesBrowserProvider provider) {
    if (provider.isLineLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (provider.lineError != null) {
      return _buildErrorState(provider.lineError!, provider);
    }

    final line = provider.selectedLine;
    if (line == null) {
      return _buildEmptyState();
    }

    if (line.stops.isEmpty) {
      return _buildNoStopsState();
    }

    return _buildStopsList(line);
  }

  Widget _buildStopsList(Line line) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${line.stops.length} תחנות',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // Stops list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: line.stops.length,
            itemBuilder: (context, index) {
              final stop = line.stops[index];
              final isFirst = index == 0;
              final isLast = index == line.stops.length - 1;

              return _buildStopItem(
                stop: stop,
                isFirst: isFirst,
                isLast: isLast,
                lineColor: line.displayColor,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStopItem({
    required LineStop stop,
    required bool isFirst,
    required bool isLast,
    required Color lineColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top line (hidden for first item)
                Container(
                  width: 3,
                  height: 16,
                  color: isFirst ? Colors.transparent : lineColor,
                ),

                // Stop dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isFirst || isLast
                        ? lineColor
                        : AppColors.scaffoldBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lineColor,
                      width: 3,
                    ),
                  ),
                ),

                // Bottom line (hidden for last item)
                Expanded(
                  child: Container(
                    width: 3,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Stop info
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isFirst || isLast
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'תחנה ${stop.stationId}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sequence number
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${stop.sequence}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, LinesBrowserProvider provider) {
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
              'שגיאה בטעינת פרטי הקו',
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
                if (provider.selectedLine != null) {
                  provider.loadLineDetails(provider.selectedLine!.id);
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
            Icons.directions_bus_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'לא נבחר קו',
            style: AppTextStyles.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNoStopsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'אין מידע על תחנות',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'לא נמצא מידע על תחנות עבור קו זה',
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
