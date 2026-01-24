import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../services/api_service.dart';

/// About Screen - App information
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  // App version - update this when releasing (keep as static on widget for external access)
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _logoTapCount = 0;
  bool _showDeveloperOptions = false;

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
            // App logo and name - tap 7 times to enable developer options
            GestureDetector(
              onTap: () {
                setState(() {
                  _logoTapCount++;
                  if (_logoTapCount >= 7 && !_showDeveloperOptions) {
                    _showDeveloperOptions = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Developer options enabled!'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  } else if (_logoTapCount < 7 && _logoTapCount >= 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${7 - _logoTapCount} taps to enable developer options'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                });
              },
              child: Container(
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
            ),
            const SizedBox(height: 16),
            Text(
              'Tremp',
              style: AppTextStyles.headline1,
            ),
            const SizedBox(height: 4),
            Text(
              'גרסה ${AboutScreen.appVersion} (${AboutScreen.buildNumber})',
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
            const SizedBox(height: 16),

            // Developer options (hidden by default)
            if (_showDeveloperOptions) _buildDeveloperOptions(),
            if (_showDeveloperOptions) const SizedBox(height: 16),

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

  Widget _buildDeveloperOptions() {
    final apiConfig = ApiConfig();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withAlpha(128),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_mode,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Developer Options',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Server mode selector
          Text(
            'Server Mode',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildServerModeButton(
                  ServerMode.mock,
                  apiConfig.serverMode == ServerMode.mock,
                  apiConfig,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildServerModeButton(
                  ServerMode.real,
                  apiConfig.serverMode == ServerMode.real,
                  apiConfig,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current URL display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Server URL:',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  apiConfig.baseUrl,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Note about app restart
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Restart app for changes to take full effect',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerModeButton(
    ServerMode mode,
    bool isSelected,
    ApiConfig apiConfig,
  ) {
    return GestureDetector(
      onTap: () async {
        await apiConfig.setServerMode(mode);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${mode.displayName}'),
              backgroundColor: AppColors.primaryBlue,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withAlpha(51)
              : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode == ServerMode.mock
                  ? Icons.science_outlined
                  : Icons.cloud_outlined,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              mode.displayName,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
