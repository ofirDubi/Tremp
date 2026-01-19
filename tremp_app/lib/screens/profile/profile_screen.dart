import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Profile/Settings Screen - User settings and preferences
/// TODO: Implement in Phase 8
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.lightBlue,
                        child: const Icon(
                          Icons.person,
                          size: 36,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'שלום!',
                              style: AppTextStyles.headline3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'אזור אישי',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Settings menu placeholder
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'היסטוריית נסיעות',
                    subtitle: 'צפייה בנסיעות קודמות',
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'הגדרות פרופיל',
                    subtitle: 'עריכת פרטים אישיים',
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: 'שפה',
                    subtitle: 'עברית',
                  ),
                  _buildMenuItem(
                    icon: Icons.support_agent,
                    title: 'שירות לקוחות',
                    subtitle: 'צור קשר עם התמיכה',
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'אודות',
                    subtitle: 'מידע על האפליקציה',
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Phase 8: Profile/Settings Screen',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: () {}, // TODO: Implement navigation
      ),
    );
  }
}
