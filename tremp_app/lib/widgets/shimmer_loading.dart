import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/colors.dart';

/// Shimmer loading widget for skeleton placeholders
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.divider.withAlpha(128),
      child: child,
    );
  }
}

/// Shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer loading skeleton for station cards
class StationCardSkeleton extends StatelessWidget {
  const StationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Station icon placeholder
            const ShimmerBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 16),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 150, height: 16),
                  SizedBox(height: 8),
                  ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            // Line badges placeholder
            const Row(
              children: [
                ShimmerBox(width: 32, height: 24, borderRadius: 4),
                SizedBox(width: 4),
                ShimmerBox(width: 32, height: 24, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading skeleton for line cards
class LineCardSkeleton extends StatelessWidget {
  const LineCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Line number badge placeholder
            const ShimmerBox(width: 48, height: 48, borderRadius: 8),
            const SizedBox(width: 16),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 180, height: 16),
                  SizedBox(height: 8),
                  ShimmerBox(width: 120, height: 12),
                ],
              ),
            ),
            // Arrow placeholder
            const ShimmerBox(width: 24, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading skeleton for arrival rows
class ArrivalRowSkeleton extends StatelessWidget {
  const ArrivalRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Line badge placeholder
            const ShimmerBox(width: 40, height: 28, borderRadius: 4),
            const SizedBox(width: 12),
            // Destination text placeholder
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 4),
                  ShimmerBox(width: 80, height: 10),
                ],
              ),
            ),
            // Time placeholder
            const ShimmerBox(width: 50, height: 24, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading skeleton for search results
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon placeholder
            const ShimmerBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 12),
            // Text placeholders
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 14),
                  SizedBox(height: 6),
                  ShimmerBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of skeleton items for loading states
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
