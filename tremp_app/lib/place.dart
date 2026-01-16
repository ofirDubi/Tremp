// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
import 'package:latlong2/latlong.dart';

class Place {
  const Place({
    this.name = '',
    this.street = '',
    this.state = '',
    this.city = '',
    this.country = '',
    this.houseNumber = '',
    this.coordinates = const LatLng(0, 0),
  });

  factory Place.fromJson(Map<String, dynamic> map) {
    final Map<String, dynamic> props =
        map['properties']! as Map<String, dynamic>;

    List<dynamic> coordinatesList =
        map['geometry']['coordinates'] as List<dynamic>? ?? [0, 0];

    return Place(
      name: props['name'] as String? ?? '',
      street: props['street'] as String? ?? '',
      state: props['state'] as String? ?? '',
      city: props['city'] as String? ?? '',
      country: props['country'] as String? ?? '',
      houseNumber: props['housenumber'] as String? ?? '',
      coordinates: LatLng(coordinatesList[1], coordinatesList[0]),
    );
  }
  final String name;
  final String street;
  final String state;
  final String city;
  final String country;
  final String houseNumber;
  final LatLng coordinates;

  bool get hasState => state.isNotEmpty == true;
  bool get hasCity => city.isNotEmpty == true;
  bool get hasName => name.isNotEmpty == true;
  bool get hasStreet => street.isNotEmpty == true;
  bool get hasCountry => country.isNotEmpty == true;
  bool get hasHouseNumber => houseNumber.isNotEmpty == true;

  bool get isCountry => hasCountry && name == country;
  bool get isState => hasState && name == state;

  // List<double> get getCoor

  String get getBaseName {
    if (hasName) {
      return name;
    }
    if (hasStreet) {
      return street;
    }
    return '';
  }

  String get level1Address {
    if (hasHouseNumber) {
      return '$houseNumber, $getBaseName';
    }
    return getBaseName;
  }

  String get address {
    if (isCountry) {
      return country;
    }

    if (hasHouseNumber) {
      return '$houseNumber, $getBaseName, $level2Address';
    }

    return '$getBaseName, $level2Address';
  }

  String get addressShort {
    if (isCountry) {
      return country;
    }
    return '$getBaseName, $country';
  }

  String get level2Address {
    if (!hasState && !hasCity) {
      return country;
    }
    if (!hasCountry) {
      return state;
    }
    return '$city, $state, $country';
  }

  @override
  String toString() =>
      'Place(houseNumber: $houseNumber, name: $getBaseName, state: $state, country: $country, coordinates: $coordinates)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Place &&
        other.name == name &&
        other.state == state &&
        other.country == country &&
        other.houseNumber == houseNumber &&
        other.street == street &&
        other.coordinates == coordinates;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      state.hashCode ^
      country.hashCode ^
      houseNumber.hashCode ^
      street.hashCode;
}
