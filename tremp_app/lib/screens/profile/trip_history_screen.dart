import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../providers/profile_provider.dart';

/// Trip History Screen - Shows past trips
class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('היסטוריית נסיעות'),
        centerTitle: true,
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.tripHistory.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearConfirmation(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.tripHistory.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildTripList(context, provider.tripHistory);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'אין נסיעות עדיין',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'הנסיעות שלך יופיעו כאן',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(BuildContext context, List<TripRecord> trips) {
    // Group trips by date
    final groupedTrips = <String, List<TripRecord>>{};
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final trip in trips) {
      final dateKey = dateFormat.format(trip.timestamp);
      groupedTrips.putIfAbsent(dateKey, () => []).add(trip);
    }

    final sortedDates = groupedTrips.keys.toList()
      ..sort((a, b) {
        final dateA = dateFormat.parse(a);
        final dateB = dateFormat.parse(b);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayTrips = groupedTrips[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getDateLabel(dateFormat.parse(dateKey)),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...dayTrips.map((trip) => _buildTripCard(context, trip)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDate = DateTime(date.year, date.month, date.day);

    if (tripDate == today) {
      return 'היום';
    } else if (tripDate == yesterday) {
      return 'אתמול';
    } else {
      return DateFormat('EEEE, d בMMMM', 'he').format(date);
    }
  }

  Widget _buildTripCard(BuildContext context, TripRecord trip) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: AppColors.primaryBlue,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.origin,
              style: AppTextStyles.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.destination,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeFormat.format(trip.timestamp),
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${trip.durationMinutes} דק\'',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('מחיקת היסטוריה'),
        content: const Text('האם אתה בטוח שברצונך למחוק את כל היסטוריית הנסיעות?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              provider.clearTripHistory();
              Navigator.of(context).pop();
            },
            child: Text(
              'מחק',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
