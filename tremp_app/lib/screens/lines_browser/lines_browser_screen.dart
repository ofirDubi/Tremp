import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Lines Browser Screen - Browse and search bus/train lines
/// TODO: Implement in Phase 6
class LinesBrowserScreen extends StatelessWidget {
  const LinesBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('קווים'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar placeholder
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.searchBarBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textTertiary),
                  const SizedBox(width: 12),
                  Text(
                    'חיפוש קו לפי מספר או יעד',
                    style: AppTextStyles.searchBarHint,
                  ),
                ],
              ),
            ),
            // Content placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_bus_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lines Browser Screen',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phase 6: Browse and search lines',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
