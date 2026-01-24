import 'line_summary.dart';
import 'location.dart';

/// A transit station (bus stop, train station, etc.)
class Station {
  final String id;
  final String name;
  final String? nameHe;
  final Location location;
  final List<LineSummary> lines;
  final String? direction;

  const Station({
    required this.id,
    required this.name,
    this.nameHe,
    required this.location,
    this.lines = const [],
    this.direction,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHe: json['name_he'] as String?,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => LineSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      direction: json['direction'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (nameHe != null) 'name_he': nameHe,
      'location': location.toJson(),
      'lines': lines.map((e) => e.toJson()).toList(),
      if (direction != null) 'direction': direction,
    };
  }

  /// Get display name (Hebrew preferred for RTL context)
  String get displayName => nameHe ?? name;

  @override
  String toString() => 'Station($id, $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Station && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
