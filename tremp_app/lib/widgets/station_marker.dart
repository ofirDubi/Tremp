import 'package:flutter/material.dart';

import '../models/station.dart';
import '../theme/colors.dart';

/// Station marker widget for displaying on the map
/// Shows as a yellow badge with the number of lines serving the station
class StationMarker extends StatelessWidget {
  final Station station;
  final bool isSelected;
  final VoidCallback? onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: _buildMarker(),
      ),
    );
  }

  Widget _buildMarker() {
    // Different sizes based on number of lines
    final lineCount = station.lines.length;
    final isLargeStation = lineCount >= 3;
    final isMediumStation = lineCount >= 2;

    final double size = isLargeStation
        ? 32
        : isMediumStation
            ? 28
            : 24;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryBlue
            : AppColors.stationMarkerYellow,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.lightBlue
              : AppColors.stationMarkerBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.4)
                : Colors.black.withOpacity(0.3),
            blurRadius: isSelected ? 8 : 4,
            spreadRadius: isSelected ? 2 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildMarkerContent(lineCount, size),
      ),
    );
  }

  Widget _buildMarkerContent(int lineCount, double size) {
    // Show line count for stations with multiple lines
    if (lineCount > 1) {
      return Text(
        lineCount.toString(),
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Show bus icon for single-line stations
    return Icon(
      Icons.directions_bus,
      color: isSelected ? Colors.white : Colors.black87,
      size: size * 0.55,
    );
  }
}

/// Simple station marker for performance (no animation)
class SimpleStationMarker extends StatelessWidget {
  final Station station;
  final bool isSelected;
  final VoidCallback? onTap;

  const SimpleStationMarker({
    super.key,
    required this.station,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lineCount = station.lines.length;
    final isLargeStation = lineCount >= 3;
    final isMediumStation = lineCount >= 2;

    final double size = isLargeStation
        ? 32
        : isMediumStation
            ? 28
            : 24;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.stationMarkerYellow,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.lightBlue
                : AppColors.stationMarkerBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: lineCount > 1
              ? Text(
                  lineCount.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(
                  Icons.directions_bus,
                  color: isSelected ? Colors.white : Colors.black87,
                  size: size * 0.55,
                ),
        ),
      ),
    );
  }
}
