import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/station.dart';

/// API service for communicating with the Tremp backend
class ApiService {
  /// Base URL for the API (mock server by default)
  static const String _mockServerUrl = 'http://localhost:8080';
  static const String _realServerUrl = 'http://localhost:8000';

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
