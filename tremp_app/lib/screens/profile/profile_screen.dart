import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/language_selector.dart';
import 'trip_history_screen.dart';
import 'profile_settings_screen.dart';
import 'about_screen.dart';

/// Profile/Settings Screen - User settings and preferences
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Profile header with blue background
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                return Container(
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
                                  provider.greeting,
                                  style: AppTextStyles.headline3.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getPersonalAreaText(provider.languageCode),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color:
                                        AppColors.textPrimary.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Settings menu
            Expanded(
              child: Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.history,
                        title: _getMenuText('trip_history', provider.languageCode),
                        subtitle: _getMenuSubtext('trip_history', provider.languageCode),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TripHistoryScreen(),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.person_outline,
                        title: _getMenuText('profile_settings', provider.languageCode),
                        subtitle: _getMenuSubtext('profile_settings', provider.languageCode),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileSettingsScreen(),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.language,
                        title: _getMenuText('language', provider.languageCode),
                        subtitle: provider.languageDisplayName,
                        onTap: () => LanguageSelector.show(context),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.support_agent,
                        title: _getMenuText('customer_service', provider.languageCode),
                        subtitle: _getMenuSubtext('customer_service', provider.languageCode),
                        onTap: () => _openCustomerService(context),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.info_outline,
                        title: _getMenuText('about', provider.languageCode),
                        subtitle: _getMenuSubtext('about', provider.languageCode),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Footer with version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v${AboutScreen.appVersion}',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPersonalAreaText(String languageCode) {
    switch (languageCode) {
      case 'he':
        return 'אזור אישי';
      case 'ar':
        return 'منطقة شخصية';
      case 'en':
      default:
        return 'Personal Area';
    }
  }

  String _getMenuText(String key, String languageCode) {
    final texts = {
      'trip_history': {
        'he': 'היסטוריית נסיעות',
        'ar': 'سجل الرحلات',
        'en': 'Trip History',
      },
      'profile_settings': {
        'he': 'הגדרות פרופיל',
        'ar': 'إعدادات الملف الشخصي',
        'en': 'Profile Settings',
      },
      'language': {
        'he': 'שפה',
        'ar': 'اللغة',
        'en': 'Language',
      },
      'customer_service': {
        'he': 'שירות לקוחות',
        'ar': 'خدمة العملاء',
        'en': 'Customer Service',
      },
      'about': {
        'he': 'אודות',
        'ar': 'حول',
        'en': 'About',
      },
    };
    return texts[key]?[languageCode] ?? texts[key]?['en'] ?? key;
  }

  String _getMenuSubtext(String key, String languageCode) {
    final subtexts = {
      'trip_history': {
        'he': 'צפייה בנסיעות קודמות',
        'ar': 'عرض الرحلات السابقة',
        'en': 'View past trips',
      },
      'profile_settings': {
        'he': 'עריכת פרטים אישיים',
        'ar': 'تعديل البيانات الشخصية',
        'en': 'Edit personal information',
      },
      'customer_service': {
        'he': 'צור קשר עם התמיכה',
        'ar': 'اتصل بالدعم',
        'en': 'Contact support',
      },
      'about': {
        'he': 'מידע על האפליקציה',
        'ar': 'معلومات عن التطبيق',
        'en': 'App information',
      },
    };
    return subtexts[key]?[languageCode] ?? subtexts[key]?['en'] ?? '';
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
        onTap: onTap,
      ),
    );
  }

  Future<void> _openCustomerService(BuildContext context) async {
    // Show options dialog for customer service
    final provider = context.read<ProfileProvider>();
    final languageCode = provider.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              _getMenuText('customer_service', languageCode),
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 24),

            _buildContactOption(
              icon: Icons.email_outlined,
              title: languageCode == 'he' ? 'שלח אימייל' : 'Send Email',
              subtitle: 'support@tremp.app',
              onTap: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse('mailto:support@tremp.app');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _buildContactOption(
              icon: Icons.phone_outlined,
              title: languageCode == 'he' ? 'התקשר' : 'Call',
              subtitle: '*2800',
              onTap: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse('tel:*2800');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        onTap: onTap,
      ),
    );
  }
}
