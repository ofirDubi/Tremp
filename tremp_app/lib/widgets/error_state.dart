import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Generic error state widget for displaying errors with retry option
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Create an error state for network errors
  factory ErrorState.network({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      title: 'שגיאת רשת',
      message: 'לא ניתן להתחבר לשרת. בדוק את החיבור לאינטרנט ונסה שוב.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Create an error state for server errors
  factory ErrorState.server({
    String? message,
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      title: 'שגיאת שרת',
      message: message ?? 'אירעה שגיאה בשרת. נסה שוב מאוחר יותר.',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  /// Create an error state for timeout errors
  factory ErrorState.timeout({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      title: 'הבקשה נכשלה',
      message: 'הבקשה ארכה זמן רב מדי. נסה שוב.',
      icon: Icons.timer_off,
      onRetry: onRetry,
    );
  }

  /// Create an error state for no data errors
  factory ErrorState.noData({
    String? message,
  }) {
    return ErrorState(
      title: 'אין מידע',
      message: message ?? 'לא נמצא מידע להצגה.',
      icon: Icons.inbox,
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('נסה שוב'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner for displaying errors in a non-blocking way
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.errorRed.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('נסה שוב'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.errorRed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }
}

/// Snackbar helper for showing error messages
void showErrorSnackbar(BuildContext context, String message, {VoidCallback? onRetry}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null
          ? SnackBarAction(
              label: 'נסה שוב',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}

/// Snackbar helper for showing success messages
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
      backgroundColor: AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
