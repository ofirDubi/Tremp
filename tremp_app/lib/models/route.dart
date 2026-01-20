import 'line_summary.dart';
import 'place.dart';

/// Time mode for route calculation
enum RouteMode {
  leaveNow,
  departAt,
  arriveBy;

  static RouteMode fromString(String value) {
    switch (value) {
      case 'leave_now':
        return RouteMode.leaveNow;
      case 'depart_at':
        return RouteMode.departAt;
      case 'arrive_by':
        return RouteMode.arriveBy;
      default:
        return RouteMode.leaveNow;
    }
  }

  String toJson() {
    switch (this) {
      case RouteMode.leaveNow:
        return 'leave_now';
      case RouteMode.departAt:
        return 'depart_at';
      case RouteMode.arriveBy:
        return 'arrive_by';
    }
  }
}

/// Type of route leg
enum RouteLegType {
  walk,
  transit,
  car;

  static RouteLegType fromString(String value) {
    switch (value) {
      case 'walk':
        return RouteLegType.walk;
      case 'transit':
        return RouteLegType.transit;
      case 'car':
        return RouteLegType.car;
      default:
        return RouteLegType.walk;
    }
  }

  String toJson() {
    switch (this) {
      case RouteLegType.walk:
        return 'walk';
      case RouteLegType.transit:
        return 'transit';
      case RouteLegType.car:
        return 'car';
    }
  }
}

/// A segment of a route (walk or transit)
class RouteLeg {
  final RouteLegType type;
  final int durationMinutes;
  final int? distanceMeters;
  final LineSummary? line;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int? stopsCount;
  final Place from;
  final Place to;

  const RouteLeg({
    required this.type,
    required this.durationMinutes,
    this.distanceMeters,
    this.line,
    this.departureTime,
    this.arrivalTime,
    this.stopsCount,
    required this.from,
    required this.to,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    return RouteLeg(
      type: RouteLegType.fromString(json['type'] as String),
      durationMinutes: json['duration_minutes'] as int,
      distanceMeters: json['distance_meters'] as int?,
      line: json['line'] != null
          ? LineSummary.fromJson(json['line'] as Map<String, dynamic>)
          : null,
      departureTime: json['departure_time'] != null
          ? DateTime.parse(json['departure_time'] as String)
          : null,
      arrivalTime: json['arrival_time'] != null
          ? DateTime.parse(json['arrival_time'] as String)
          : null,
      stopsCount: json['stops_count'] as int?,
      from: Place.fromJson(json['from'] as Map<String, dynamic>),
      to: Place.fromJson(json['to'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'duration_minutes': durationMinutes,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (line != null) 'line': line!.toJson(),
      if (departureTime != null) 'departure_time': departureTime!.toIso8601String(),
      if (arrivalTime != null) 'arrival_time': arrivalTime!.toIso8601String(),
      if (stopsCount != null) 'stops_count': stopsCount,
      'from': from.toJson(),
      'to': to.toJson(),
    };
  }

  /// Whether this is a walking leg
  bool get isWalking => type == RouteLegType.walk;

  /// Whether this is a transit leg
  bool get isTransit => type == RouteLegType.transit;

  @override
  String toString() => 'RouteLeg(${type.toJson()}, $durationMinutes min)';
}

/// A calculated transit route
class TransitRoute {
  final String id;
  final int totalDurationMinutes;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int transfers;
  final int? walkingDurationMinutes;
  final List<RouteLeg> legs;

  const TransitRoute({
    required this.id,
    required this.totalDurationMinutes,
    required this.departureTime,
    required this.arrivalTime,
    required this.transfers,
    this.walkingDurationMinutes,
    required this.legs,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) {
    return TransitRoute(
      id: json['id'] as String,
      totalDurationMinutes: json['total_duration_minutes'] as int,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      transfers: json['transfers'] as int,
      walkingDurationMinutes: json['walking_duration_minutes'] as int?,
      legs: (json['legs'] as List<dynamic>)
          .map((e) => RouteLeg.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_duration_minutes': totalDurationMinutes,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'transfers': transfers,
      if (walkingDurationMinutes != null)
        'walking_duration_minutes': walkingDurationMinutes,
      'legs': legs.map((e) => e.toJson()).toList(),
    };
  }

  /// Get transit legs only
  List<RouteLeg> get transitLegs =>
      legs.where((leg) => leg.isTransit).toList();

  /// Get formatted departure time
  String get formattedDepartureTime {
    return '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted arrival time
  String get formattedArrivalTime {
    return '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'TransitRoute($id, $totalDurationMinutes min, $transfers transfers)';
}
