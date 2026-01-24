import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/profile_provider.dart';

/// Language selector bottom sheet
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  /// Show the language selector bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LanguageSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Container(
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

              // Title
              Text(
                'בחר שפה',
                style: AppTextStyles.headline3,
              ),
              const SizedBox(height: 8),
              Text(
                'Select Language',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Language options
              ...ProfileProvider.availableLanguages.map((language) {
                final isSelected = provider.languageCode == language.code;
                return _buildLanguageOption(
                  context: context,
                  language: language,
                  isSelected: isSelected,
                  onTap: () async {
                    await provider.setLanguage(language.code);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _getLanguageChangedMessage(language.code),
                          ),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageChangedMessage(String code) {
    switch (code) {
      case 'he':
        return 'השפה שונתה לעברית';
      case 'ar':
        return 'تم تغيير اللغة إلى العربية';
      case 'en':
      default:
        return 'Language changed to English';
    }
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required LanguageOption language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryBlue.withOpacity(0.2)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primaryBlue, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _getLanguageIcon(language.code),
        title: Text(
          language.name,
          style: AppTextStyles.titleMedium.copyWith(
            color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          language.nativeName,
          style: AppTextStyles.bodySmall,
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _getLanguageIcon(String code) {
    // Simple text-based flag representation
    String flagEmoji;
    switch (code) {
      case 'he':
        flagEmoji = 'HE';
        break;
      case 'ar':
        flagEmoji = 'AR';
        break;
      case 'en':
      default:
        flagEmoji = 'EN';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          flagEmoji,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
