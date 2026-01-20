import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/arrival.dart';
import '../models/station.dart';

/// API service for communicating with the Tremp backend
class ApiService {
  /// Base URL for the API (mock server by default)
  /// Note: Android emulator uses 10.0.2.2 to reach host localhost
  static const String _mockServerUrl = 'http://10.0.2.2:8080';
  static const String _realServerUrl = 'http://10.0.2.2:8000';

  final String _baseUrl;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? _mockServerUrl,
        _client = client ?? http.Client();

  /// Create an ApiService pointing to the mock server
  factory ApiService.mock() {
    return ApiService(baseUrl: _mockServerUrl);
  }

  /// Create an ApiService pointing to the real server
  factory ApiService.real() {
    return ApiService(baseUrl: _realServerUrl);
  }

  /// Get stations within a bounding box
  Future<List<Station>> getStations({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int limit = 100,
  }) async {
    final uri = Uri.parse('$_baseUrl/stations').replace(
      queryParameters: {
        'min_lat': minLat.toString(),
        'max_lat': maxLat.toString(),
        'min_lon': minLon.toString(),
        'max_lon': maxLon.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final stations = data['stations'] as List<dynamic>;
      return stations
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch stations',
      );
    }
  }

  /// Get a single station by ID
  Future<Station> getStation(String id) async {
    final uri = Uri.parse('$_baseUrl/station/$id');

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return Station.fromJson(data);
    } else if (response.statusCode == 404) {
      throw ApiException(
        statusCode: 404,
        message: 'Station not found',
      );
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch station',
      );
    }
  }

  /// Get real-time arrivals for a station
  Future<List<Arrival>> getArrivals({
    required String stationId,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/arrivals').replace(
      queryParameters: {
        'station_id': stationId,
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final arrivals = data['arrivals'] as List<dynamic>;
      return arrivals
          .map((e) => Arrival.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      throw ApiException(
        statusCode: 404,
        message: 'Station not found',
      );
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch arrivals',
      );
    }
  }

  /// Get stations near a location (for Nearby Routes)
  Future<List<Station>> getNearbyStations({
    required double lat,
    required double lon,
    int radius = 500,
  }) async {
    final uri = Uri.parse('$_baseUrl/stations/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius': radius.toString(),
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final stations = data['stations'] as List<dynamic>;
      return stations
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch nearby stations',
      );
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// API exception with status code and message
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
