import 'package:flutter/material.dart';

import '../models/line_summary.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// A small colored badge displaying a line number
class LineBadge extends StatelessWidget {
  final LineSummary line;
  final VoidCallback? onTap;
  final bool compact;

  const LineBadge({
    super.key,
    required this.line,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 36.0;
    final fontSize = compact ? 10.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: size,
          minHeight: compact ? 22.0 : 28.0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: line.displayColor,
          borderRadius: BorderRadius.circular(compact ? 4 : 6),
        ),
        child: Center(
          child: Text(
            line.number,
            style: AppTextStyles.lineNumber.copyWith(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of line badges with overflow handling
class LineBadgesRow extends StatelessWidget {
  final List<LineSummary> lines;
  final int maxVisible;
  final bool compact;
  final void Function(LineSummary line)? onLineTap;

  const LineBadgesRow({
    super.key,
    required this.lines,
    this.maxVisible = 5,
    this.compact = false,
    this.onLineTap,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleLines = lines.take(maxVisible).toList();
    final overflowCount = lines.length - maxVisible;

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 4 : 6,
      children: [
        ...visibleLines.map((line) => LineBadge(
              line: line,
              compact: compact,
              onTap: onLineTap != null ? () => onLineTap!(line) : null,
            )),
        if (overflowCount > 0)
          Container(
            constraints: BoxConstraints(
              minWidth: compact ? 28.0 : 36.0,
              minHeight: compact ? 22.0 : 28.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(compact ? 4 : 6),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '+$overflowCount',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: compact ? 10.0 : 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
