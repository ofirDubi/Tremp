import 'package:flutter/material.dart';

/// Tremp app color palette - Dark theme
class AppColors {
  AppColors._();

  // Background colors
  static const Color scaffoldBackground = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF252525);
  static const Color bottomSheetColor = Color(0xFF2A2A2A);
  static const Color bottomNavBackground = Color(0xFF1A1A1A);

  // Primary accent colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color activeTabBlue = Color(0xFF42A5F5);
  static const Color lightBlue = Color(0xFF64B5F6);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF5C5C5C);

  // Station and map markers
  static const Color stationMarkerYellow = Color(0xFFFFD600);
  static const Color stationMarkerBorder = Color(0xFFE6C200);

  // Transit line colors by type
  static const Color busGreen = Color(0xFF4CAF50);
  static const Color trainOrange = Color(0xFFFF9800);
  static const Color tramRed = Color(0xFFF44336);
  static const Color lightRailPurple = Color(0xFF9C27B0);

  // Operator brand colors
  static const Color eggedGreen = Color(0xFF4CAF50);
  static const Color danBlue = Color(0xFF2196F3);
  static const Color kavimOrange = Color(0xFFFF9800);
  static const Color metropolinePurple = Color(0xFF7B1FA2);
  static const Color superbusRed = Color(0xFFE53935);
  static const Color israelRailwaysBlue = Color(0xFF1565C0);

  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Realtime indicator
  static const Color realtimeGreen = Color(0xFF00E676);
  static const Color scheduledGray = Color(0xFF9E9E9E);

  // Dividers and borders
  static const Color divider = Color(0xFF3D3D3D);
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF505050);

  // Shimmer loading colors
  static const Color shimmerBase = Color(0xFF2A2A2A);
  static const Color shimmerHighlight = Color(0xFF3A3A3A);

  // Search bar
  static const Color searchBarBackground = Color(0xFF2E2E2E);
  static const Color searchBarHint = Color(0xFF888888);

  /// Get operator color by operator code
  static Color getOperatorColor(String operator) {
    switch (operator.toLowerCase()) {
      case 'egged':
        return eggedGreen;
      case 'dan':
        return danBlue;
      case 'kavim':
        return kavimOrange;
      case 'metropoline':
        return metropolinePurple;
      case 'superbus':
        return superbusRed;
      case 'israel_railways':
        return israelRailwaysBlue;
      default:
        return primaryBlue;
    }
  }

  /// Get transit type color
  static Color getTransitTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return busGreen;
      case 'train':
      case 'rail':
        return trainOrange;
      case 'tram':
        return tramRed;
      case 'light_rail':
        return lightRailPurple;
      default:
        return primaryBlue;
    }
  }
}
