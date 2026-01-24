import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/arrival.dart';
import '../models/line.dart';
import '../models/location.dart';
import '../models/place.dart';
import '../models/route.dart';
import '../models/station.dart';

/// Server mode for API configuration
enum ServerMode {
  mock,
  real;

  String get displayName {
    switch (this) {
      case ServerMode.mock:
        return 'Mock Server';
      case ServerMode.real:
        return 'Real Server';
    }
  }
}

/// API configuration for managing server endpoints
class ApiConfig {
  /// Singleton instance
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  /// Preference key for server mode
  static const String _serverModeKey = 'server_mode';

  /// Server URLs
  /// Note: Android emulator uses 10.0.2.2 to reach host localhost
  static const String mockServerUrl = 'http://10.0.2.2:8080';
  static const String realServerUrl = 'http://10.0.2.2:8000';

  /// Current server mode (defaults to mock)
  ServerMode _serverMode = ServerMode.mock;

  /// Get current server mode
  ServerMode get serverMode => _serverMode;

  /// Get current base URL based on server mode
  String get baseUrl {
    switch (_serverMode) {
      case ServerMode.mock:
        return mockServerUrl;
      case ServerMode.real:
        return realServerUrl;
    }
  }

  /// Initialize configuration from stored preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_serverModeKey);
    if (modeString != null) {
      _serverMode = ServerMode.values.firstWhere(
        (m) => m.name == modeString,
        orElse: () => ServerMode.mock,
      );
    }
  }

  /// Set server mode and persist to preferences
  Future<void> setServerMode(ServerMode mode) async {
    _serverMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverModeKey, mode.name);
  }

  /// Toggle between mock and real server
  Future<void> toggleServerMode() async {
    final newMode = _serverMode == ServerMode.mock
        ? ServerMode.real
        : ServerMode.mock;
    await setServerMode(newMode);
  }
}

/// API service for communicating with the Tremp backend
class ApiService {
  final http.Client _client;
  final ApiConfig _config;

  ApiService({
    http.Client? client,
    ApiConfig? config,
  })  : _client = client ?? http.Client(),
        _config = config ?? ApiConfig();

  /// Get current base URL
  String get _baseUrl => _config.baseUrl;

  /// Get current server mode
  ServerMode get serverMode => _config.serverMode;

  /// Set server mode
  Future<void> setServerMode(ServerMode mode) => _config.setServerMode(mode);

  /// Toggle between mock and real server
  Future<void> toggleServerMode() => _config.toggleServerMode();

  /// Create an ApiService pointing to the mock server
  factory ApiService.mock() {
    final config = ApiConfig();
    config._serverMode = ServerMode.mock;
    return ApiService(config: config);
  }

  /// Create an ApiService pointing to the real server
  factory ApiService.real() {
    final config = ApiConfig();
    config._serverMode = ServerMode.real;
    return ApiService(config: config);
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

  /// Search stations by ID or name
  Future<List<Station>> searchStations({
    String? query,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }

    final uri = Uri.parse('$_baseUrl/stations/search').replace(
      queryParameters: queryParams,
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
        message: 'Failed to search stations',
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

  /// Get transit lines
  Future<List<Line>> getLines({
    String? query,
    String? operator,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (operator != null && operator.isNotEmpty) {
      queryParams['operator'] = operator;
    }

    final uri = Uri.parse('$_baseUrl/lines').replace(
      queryParameters: queryParams,
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final lines = data['lines'] as List<dynamic>;
      return lines
          .map((e) => Line.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch lines',
      );
    }
  }

  /// Get a single line by ID (with stops)
  Future<Line> getLine(String id, {int direction = 0}) async {
    final uri = Uri.parse('$_baseUrl/line/$id').replace(
      queryParameters: {
        'direction': direction.toString(),
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return Line.fromJson(data);
    } else if (response.statusCode == 404) {
      throw ApiException(
        statusCode: 404,
        message: 'Line not found',
      );
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch line',
      );
    }
  }

  /// Search for places (autocomplete)
  Future<List<Place>> searchPlaces({
    required String query,
    double? lat,
    double? lon,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'limit': limit.toString(),
    };
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lon != null) queryParams['lon'] = lon.toString();

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: queryParams,
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to search places',
      );
    }
  }

  /// Calculate transit route
  Future<List<TransitRoute>> calculateRoute({
    required Location origin,
    required Location destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    RouteMode mode = RouteMode.leaveNow,
  }) async {
    final uri = Uri.parse('$_baseUrl/route');

    final body = <String, dynamic>{
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'mode': mode.toJson(),
    };
    if (departureTime != null) {
      body['departure_time'] = departureTime.toIso8601String();
    }
    if (arrivalTime != null) {
      body['arrival_time'] = arrivalTime.toIso8601String();
    }

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>;
      return routes
          .map((e) => TransitRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to calculate route',
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
