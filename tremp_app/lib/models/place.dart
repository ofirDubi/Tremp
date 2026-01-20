import 'location.dart';

/// Type of place for search results
enum PlaceType {
  station,
  address,
  poi,
  currentLocation;

  static PlaceType fromString(String value) {
    switch (value) {
      case 'station':
        return PlaceType.station;
      case 'address':
        return PlaceType.address;
      case 'poi':
        return PlaceType.poi;
      case 'current_location':
        return PlaceType.currentLocation;
      default:
        return PlaceType.address;
    }
  }

  String toJson() {
    switch (this) {
      case PlaceType.station:
        return 'station';
      case PlaceType.address:
        return 'address';
      case PlaceType.poi:
        return 'poi';
      case PlaceType.currentLocation:
        return 'current_location';
    }
  }
}

/// A location (station, address, or POI) for search results and route endpoints
class Place {
  final String? id;
  final PlaceType? type;
  final String name;
  final String? nameHe;
  final String? address;
  final Location location;

  const Place({
    this.id,
    this.type,
    required this.name,
    this.nameHe,
    this.address,
    required this.location,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String?,
      type: json['type'] != null
          ? PlaceType.fromString(json['type'] as String)
          : null,
      name: json['name'] as String,
      nameHe: json['name_he'] as String?,
      address: json['address'] as String?,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (type != null) 'type': type!.toJson(),
      'name': name,
      if (nameHe != null) 'name_he': nameHe,
      if (address != null) 'address': address,
      'location': location.toJson(),
    };
  }

  /// Get display name (Hebrew preferred for RTL context)
  String get displayName => nameHe ?? name;

  /// Create a Place for current location
  factory Place.currentLocation(Location location) {
    return Place(
      type: PlaceType.currentLocation,
      name: 'Current Location',
      nameHe: 'המיקום הנוכחי',
      location: location,
    );
  }

  @override
  String toString() => 'Place($name, ${type?.toJson()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Place &&
        other.id == id &&
        other.name == name &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(id, name, location);
}
