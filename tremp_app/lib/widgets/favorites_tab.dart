import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Tab content showing user's favorite locations
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to favorites storage (SharedPreferences) in Phase 5
    // For now, show a placeholder with home/work quick actions

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Quick action cards
        _buildQuickActionCard(
          icon: Icons.home_outlined,
          label: 'בית',
          subtitle: 'הגדר מיקום',
          onTap: () {
            // TODO: Navigate to set home location
          },
        ),
        const SizedBox(height: 8),
        _buildQuickActionCard(
          icon: Icons.work_outlined,
          label: 'עבודה',
          subtitle: 'הגדר מיקום',
          onTap: () {
            // TODO: Navigate to set work location
          },
        ),
        const SizedBox(height: 16),

        // Add favorite button
        _buildAddFavoriteButton(context),

        const SizedBox(height: 24),

        // Empty state message
        Center(
          child: Column(
            children: [
              Icon(
                Icons.star_border,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'אין מועדפים',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'הוסף מקומות למועדפים לגישה מהירה',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.cardBackground,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.titleSmall,
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.add,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFavoriteButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Navigate to add favorite location
      },
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('הוסף מקום מועדף'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
