import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Brief line information for badges/markers
class LineSummary {
  final String id;
  final String number;
  final String operator;
  final String? color;

  const LineSummary({
    required this.id,
    required this.number,
    required this.operator,
    this.color,
  });

  factory LineSummary.fromJson(Map<String, dynamic> json) {
    return LineSummary(
      id: json['id'] as String,
      number: json['number'] as String,
      operator: json['operator'] as String,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'operator': operator,
      if (color != null) 'color': color,
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

  @override
  String toString() => 'LineSummary($number, $operator)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LineSummary && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
