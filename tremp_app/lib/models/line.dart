import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'location.dart';

/// A transit line (bus, train, etc.)
class Line {
  final String id;
  final String number;
  final String operator;
  final String? operatorName;
  final String? operatorNameHe;
  final String direction;
  final String? directionHe;
  final String? color;
  final int stopsCount;
  final List<LineStop> stops;

  const Line({
    required this.id,
    required this.number,
    required this.operator,
    this.operatorName,
    this.operatorNameHe,
    required this.direction,
    this.directionHe,
    this.color,
    this.stopsCount = 0,
    this.stops = const [],
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      id: json['id'] as String,
      number: json['number'] as String,
      operator: json['operator'] as String,
      operatorName: json['operator_name'] as String?,
      operatorNameHe: json['operator_name_he'] as String?,
      direction: json['direction'] as String,
      directionHe: json['direction_he'] as String?,
      color: json['color'] as String?,
      stopsCount: json['stops_count'] as int? ?? 0,
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => LineStop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'operator': operator,
      if (operatorName != null) 'operator_name': operatorName,
      if (operatorNameHe != null) 'operator_name_he': operatorNameHe,
      'direction': direction,
      if (directionHe != null) 'direction_he': directionHe,
      if (color != null) 'color': color,
      'stops_count': stopsCount,
      'stops': stops.map((e) => e.toJson()).toList(),
    };
  }

  /// Get the display color for this line
  Color get displayColor {
    if (color != null && color!.startsWith('#')) {
      try {
        final hex = color!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        // Fall back to operator color
      }
    }
    return AppColors.getOperatorColor(operator);
  }

  /// Get display direction (Hebrew preferred)
  String get displayDirection => directionHe ?? direction;

  /// Get display operator name (Hebrew preferred)
  String get displayOperatorName => operatorNameHe ?? operatorName ?? operator;

  @override
  String toString() => 'Line($number, $operator)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Line && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// A stop on a transit line
class LineStop {
  final String stationId;
  final String name;
  final String? nameHe;
  final int sequence;
  final Location location;

  const LineStop({
    required this.stationId,
    required this.name,
    this.nameHe,
    required this.sequence,
    required this.location,
  });

  factory LineStop.fromJson(Map<String, dynamic> json) {
    return LineStop(
      stationId: json['station_id'] as String,
      name: json['name'] as String,
      nameHe: json['name_he'] as String?,
      sequence: json['sequence'] as int,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'name': name,
      if (nameHe != null) 'name_he': nameHe,
      'sequence': sequence,
      'location': location.toJson(),
    };
  }

  /// Get display name (Hebrew preferred)
  String get displayName => nameHe ?? name;

  @override
  String toString() => 'LineStop($stationId, $name)';
}
