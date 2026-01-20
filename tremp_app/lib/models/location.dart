/// Geographic coordinates model
class Location {
  final double lat;
  final double lon;

  const Location({
    required this.lat,
    required this.lon,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }

  @override
  String toString() => 'Location($lat, $lon)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.lat == lat && other.lon == lon;
  }

  @override
  int get hashCode => lat.hashCode ^ lon.hashCode;
}
