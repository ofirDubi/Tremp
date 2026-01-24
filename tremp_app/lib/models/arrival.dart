import 'line_summary.dart';

/// An upcoming arrival at a station
class Arrival {
  final LineSummary line;
  final String destination;
  final String? destinationHe;
  final DateTime arrivalTime;
  final int? minutesUntil;
  final bool isRealtime;
  final DateTime? nextArrivalTime;

  const Arrival({
    required this.line,
    required this.destination,
    this.destinationHe,
    required this.arrivalTime,
    this.minutesUntil,
    required this.isRealtime,
    this.nextArrivalTime,
  });

  factory Arrival.fromJson(Map<String, dynamic> json) {
    return Arrival(
      line: LineSummary.fromJson(json['line'] as Map<String, dynamic>),
      destination: json['destination'] as String,
      destinationHe: json['destination_he'] as String?,
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      minutesUntil: json['minutes_until'] as int?,
      isRealtime: json['is_realtime'] as bool,
      nextArrivalTime: json['next_arrival_time'] != null
          ? DateTime.parse(json['next_arrival_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line': line.toJson(),
      'destination': destination,
      if (destinationHe != null) 'destination_he': destinationHe,
      'arrival_time': arrivalTime.toIso8601String(),
      if (minutesUntil != null) 'minutes_until': minutesUntil,
      'is_realtime': isRealtime,
      if (nextArrivalTime != null)
        'next_arrival_time': nextArrivalTime!.toIso8601String(),
    };
  }

  /// Get display destination (Hebrew preferred for RTL context)
  String get displayDestination => destinationHe ?? destination;

  /// Get minutes until arrival, calculated if not provided
  int getMinutesUntil([DateTime? now]) {
    if (minutesUntil != null) return minutesUntil!;
    final currentTime = now ?? DateTime.now();
    return arrivalTime.difference(currentTime).inMinutes;
  }

  /// Formatted arrival time (HH:mm)
  String get formattedTime {
    final hour = arrivalTime.hour.toString().padLeft(2, '0');
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  String toString() =>
      'Arrival(${line.number} -> $destination at $arrivalTime)';
}
