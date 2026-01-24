import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// About Screen - App information
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // App version - update this when releasing
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('אודות'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App logo and name
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tremp',
              style: AppTextStyles.headline1,
            ),
            const SizedBox(height: 4),
            Text(
              'גרסה $appVersion ($buildNumber)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'על האפליקציה',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tremp היא אפליקציה לתכנון מסלולי תחבורה ציבורית בישראל. '
                    'האפליקציה משלבת אוטובוסים, רכבות ותחבורה משותפת כדי למצוא '
                    'את המסלול הטוב ביותר עבורך.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Features
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'תכונות עיקריות',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.map_outlined,
                    text: 'מפת תחנות בזמן אמת',
                  ),
                  _buildFeatureItem(
                    icon: Icons.search,
                    text: 'חיפוש מסלולים מתקדם',
                  ),
                  _buildFeatureItem(
                    icon: Icons.directions_bus_outlined,
                    text: 'מידע על קווים ותחנות',
                  ),
                  _buildFeatureItem(
                    icon: Icons.access_time,
                    text: 'זמני הגעה בזמן אמת',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data sources
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'מקורות מידע',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'הנתונים מבוססים על מידע GTFS ממשרד התחבורה '
                    'ומידע בזמן אמת ממפעילי התחבורה השונים.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Legal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'משפטי',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildLegalLink(
                    context,
                    text: 'תנאי שימוש',
                    onTap: () => _showLegalDialog(
                      context,
                      'תנאי שימוש',
                      'השימוש באפליקציה כפוף לתנאי השימוש. '
                          'האפליקציה מסופקת כמות שהיא (AS IS) ללא אחריות.',
                    ),
                  ),
                  _buildLegalLink(
                    context,
                    text: 'מדיניות פרטיות',
                    onTap: () => _showLegalDialog(
                      context,
                      'מדיניות פרטיות',
                      'אנו מכבדים את פרטיותך. '
                          'האפליקציה אוספת מידע על מיקום רק לצורך תכנון מסלולים. '
                          'המידע נשמר באופן מקומי במכשיר ואינו נשלח לשרתים חיצוניים.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 2026 Tremp',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              'All Rights Reserved',
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(
    BuildContext context, {
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }
}
