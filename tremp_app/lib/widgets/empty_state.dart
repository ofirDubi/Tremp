import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Generic empty state widget for displaying when no data is available
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.action,
  });

  /// Create an empty state for search results
  factory EmptyState.noSearchResults({
    String? subtitle,
  }) {
    return EmptyState(
      title: 'לא נמצאו תוצאות',
      subtitle: subtitle ?? 'נסה לחפש מילות מפתח אחרות',
      icon: Icons.search_off,
    );
  }

  /// Create an empty state for stations
  factory EmptyState.noStations({
    String? subtitle,
    Widget? action,
  }) {
    return EmptyState(
      title: 'אין תחנות',
      subtitle: subtitle ?? 'לא נמצאו תחנות באזור זה',
      icon: Icons.location_off,
      action: action,
    );
  }

  /// Create an empty state for lines
  factory EmptyState.noLines({
    String? subtitle,
    Widget? action,
  }) {
    return EmptyState(
      title: 'אין קווים',
      subtitle: subtitle ?? 'לא נמצאו קווים להצגה',
      icon: Icons.directions_bus_filled,
      action: action,
    );
  }

  /// Create an empty state for arrivals
  factory EmptyState.noArrivals({
    String? subtitle,
  }) {
    return EmptyState(
      title: 'אין הגעות',
      subtitle: subtitle ?? 'לא נמצאו הגעות קרובות לתחנה זו',
      icon: Icons.schedule,
    );
  }

  /// Create an empty state for routes
  factory EmptyState.noRoutes({
    String? subtitle,
    Widget? action,
  }) {
    return EmptyState(
      title: 'לא נמצא מסלול',
      subtitle: subtitle ?? 'לא נמצא מסלול בין הנקודות שנבחרו',
      icon: Icons.route,
      action: action,
    );
  }

  /// Create an empty state for favorites
  factory EmptyState.noFavorites({
    String? subtitle,
    Widget? action,
  }) {
    return EmptyState(
      title: 'אין מועדפים',
      subtitle: subtitle ?? 'הוסף מקומות מועדפים לגישה מהירה',
      icon: Icons.star_outline,
      action: action,
    );
  }

  /// Create an empty state for recent items
  factory EmptyState.noRecent({
    String? subtitle,
  }) {
    return EmptyState(
      title: 'אין פריטים אחרונים',
      subtitle: subtitle ?? 'חפש קווים או תחנות כדי לראות אותם כאן',
      icon: Icons.history,
    );
  }

  /// Create an empty state for trip history
  factory EmptyState.noHistory({
    String? subtitle,
  }) {
    return EmptyState(
      title: 'אין היסטוריה',
      subtitle: subtitle ?? 'נסיעות שתתכנן יופיעו כאן',
      icon: Icons.history,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.primaryBlue.withAlpha(179),
          ),
        ],
      ),
    );
  }
}

/// Small inline empty state for sections within screens
class EmptyStateInline extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateInline({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
