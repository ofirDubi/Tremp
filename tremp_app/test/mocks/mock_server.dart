import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Mock server for Tremp API testing.
/// Implements the OpenAPI specification at openspec/api/tremp-api.yaml
///
/// Usage:
///   dart test/mocks/mock_server.dart [--port=8080] [--delay=0] [--error-mode=none]
///
/// Options:
///   --port: Port to listen on (default: 8080)
///   --delay: Simulated network latency in milliseconds (default: 0)
///   --error-mode: Error simulation mode (none, random, always) (default: none)

class MockServer {
  final int port;
  final int delayMs;
  final String errorMode;

  late HttpServer _server;
  late Map<String, dynamic> _stationsData;
  late Map<String, dynamic> _linesData;
  late Map<String, dynamic> _arrivalsData;

  final Random _random = Random();

  MockServer({
    this.port = 8080,
    this.delayMs = 0,
    this.errorMode = 'none',
  });

  Future<void> start() async {
    await _loadMockData();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Mock server running on http://localhost:$port');
    print('Delay: ${delayMs}ms, Error mode: $errorMode');

    await for (final request in _server) {
      _handleRequest(request);
    }
  }

  Future<void> stop() async {
    await _server.close();
    print('Mock server stopped');
  }

  Future<void> _loadMockData() async {
    final scriptDir = File(Platform.script.toFilePath()).parent.path;

    final stationsFile = File('$scriptDir/mock_data/stations.json');
    _stationsData = jsonDecode(await stationsFile.readAsString());

    final linesFile = File('$scriptDir/mock_data/lines.json');
    _linesData = jsonDecode(await linesFile.readAsString());

    final arrivalsFile = File('$scriptDir/mock_data/arrivals.json');
    _arrivalsData = jsonDecode(await arrivalsFile.readAsString());

    print('Loaded mock data:');
    print('  - ${(_stationsData['stations'] as List).length} stations');
    print('  - ${(_linesData['lines'] as List).length} lines');
    print('  - ${(_arrivalsData['arrivals_by_station'] as Map).length} station arrivals');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Add simulated delay
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // Check for error simulation
    if (_shouldSimulateError()) {
      _sendError(request.response, 500, 'SIMULATED_ERROR', 'Simulated server error');
      return;
    }

    // Set CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    final method = request.method;

    print('${DateTime.now().toIso8601String()} $method $path');

    try {
      if (method == 'GET') {
        if (path == '/stations') {
          await _handleGetStations(request);
        } else if (path == '/stations/nearby') {
          await _handleGetNearbyStations(request);
        } else if (path == '/stations/search') {
          await _handleSearchStations(request);
        } else if (path.startsWith('/station/')) {
          await _handleGetStation(request);
        } else if (path == '/lines') {
          await _handleGetLines(request);
        } else if (path.startsWith('/line/')) {
          await _handleGetLine(request);
        } else if (path == '/arrivals') {
          await _handleGetArrivals(request);
        } else if (path == '/search') {
          await _handleSearch(request);
        } else {
          _sendError(request.response, 404, 'NOT_FOUND', 'Endpoint not found');
        }
      } else if (method == 'POST') {
        if (path == '/route') {
          await _handlePostRoute(request);
        } else {
          _sendError(request.response, 404, 'NOT_FOUND', 'Endpoint not found');
        }
      } else {
        _sendError(request.response, 405, 'METHOD_NOT_ALLOWED', 'Method not allowed');
      }
    } catch (e, stackTrace) {
      print('Error handling request: $e\n$stackTrace');
      _sendError(request.response, 500, 'INTERNAL_ERROR', 'Internal server error: $e');
    }
  }

  bool _shouldSimulateError() {
    switch (errorMode) {
      case 'always':
        return true;
      case 'random':
        return _random.nextDouble() < 0.1; // 10% error rate
      default:
        return false;
    }
  }

  // GET /stations - Get stations within bounding box
  Future<void> _handleGetStations(HttpRequest request) async {
    final params = request.uri.queryParameters;

    final minLat = double.tryParse(params['min_lat'] ?? '');
    final maxLat = double.tryParse(params['max_lat'] ?? '');
    final minLon = double.tryParse(params['min_lon'] ?? '');
    final maxLon = double.tryParse(params['max_lon'] ?? '');
    final limit = int.tryParse(params['limit'] ?? '100') ?? 100;

    if (minLat == null || maxLat == null || minLon == null || maxLon == null) {
      _sendError(request.response, 400, 'INVALID_PARAMS',
          'Missing or invalid bounding box parameters (min_lat, max_lat, min_lon, max_lon)');
      return;
    }

    final allStations = _stationsData['stations'] as List;
    final filteredStations = allStations.where((station) {
      final lat = (station['location']['lat'] as num).toDouble();
      final lon = (station['location']['lon'] as num).toDouble();
      return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
    }).take(limit).toList();

    _sendJson(request.response, {'stations': filteredStations});
  }

  // GET /stations/nearby - Get stations near a location
  Future<void> _handleGetNearbyStations(HttpRequest request) async {
    final params = request.uri.queryParameters;

    final lat = double.tryParse(params['lat'] ?? '');
    final lon = double.tryParse(params['lon'] ?? '');
    final radius = int.tryParse(params['radius'] ?? '500') ?? 500;

    if (lat == null || lon == null) {
      _sendError(request.response, 400, 'INVALID_PARAMS',
          'Missing or invalid location parameters (lat, lon)');
      return;
    }

    final allStations = _stationsData['stations'] as List;
    final stationsWithDistance = <Map<String, dynamic>>[];

    for (final station in allStations) {
      final stationLat = (station['location']['lat'] as num).toDouble();
      final stationLon = (station['location']['lon'] as num).toDouble();
      final distance = _calculateDistance(lat, lon, stationLat, stationLon);

      if (distance <= radius) {
        final stationCopy = Map<String, dynamic>.from(station);
        stationCopy['distance_meters'] = distance.round();
        stationsWithDistance.add(stationCopy);
      }
    }

    // Sort by distance
    stationsWithDistance.sort((a, b) =>
        (a['distance_meters'] as int).compareTo(b['distance_meters'] as int));

    _sendJson(request.response, {'stations': stationsWithDistance});
  }

  // GET /stations/search - Search stations by ID or name
  Future<void> _handleSearchStations(HttpRequest request) async {
    final params = request.uri.queryParameters;

    final query = params['q']?.toLowerCase();
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;

    var stations = (_stationsData['stations'] as List).toList();

    // Filter by query (searches ID and name)
    if (query != null && query.isNotEmpty) {
      stations = stations.where((station) {
        final id = (station['id'] as String).toLowerCase();
        final name = (station['name'] as String).toLowerCase();
        final nameHe = (station['name_he'] as String?)?.toLowerCase() ?? '';
        return id.contains(query) ||
               name.contains(query) ||
               nameHe.contains(query);
      }).toList();
    }

    _sendJson(request.response, {'stations': stations.take(limit).toList()});
  }

  // GET /station/{id} - Get station details
  Future<void> _handleGetStation(HttpRequest request) async {
    final pathParts = request.uri.path.split('/');
    if (pathParts.length < 3) {
      _sendError(request.response, 400, 'INVALID_PARAMS', 'Missing station ID');
      return;
    }
    final stationId = pathParts[2];

    final allStations = _stationsData['stations'] as List;
    final station = allStations.firstWhere(
      (s) => s['id'] == stationId,
      orElse: () => null,
    );

    if (station == null) {
      _sendError(request.response, 404, 'NOT_FOUND', 'Station not found');
      return;
    }

    // Add arrivals data
    final stationResponse = Map<String, dynamic>.from(station);
    final arrivalsMap = _arrivalsData['arrivals_by_station'] as Map<String, dynamic>;
    final stationArrivals = arrivalsMap[stationId];

    if (stationArrivals != null) {
      stationResponse['arrivals'] = _generateDynamicArrivals(
          stationArrivals['arrivals'] as List);
    } else {
      stationResponse['arrivals'] = [];
    }

    // Add address
    stationResponse['address'] = '${station['name']}, Tel Aviv';

    _sendJson(request.response, stationResponse);
  }

  // GET /lines - Get transit lines
  Future<void> _handleGetLines(HttpRequest request) async {
    final params = request.uri.queryParameters;

    final query = params['q']?.toLowerCase();
    final operator = params['operator'];
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;

    var lines = (_linesData['lines'] as List).map((line) {
      // Return line without stops for list view
      final lineCopy = Map<String, dynamic>.from(line);
      lineCopy.remove('stops');
      return lineCopy;
    }).toList();

    // Filter by query
    if (query != null && query.isNotEmpty) {
      lines = lines.where((line) {
        final number = (line['number'] as String).toLowerCase();
        final direction = (line['direction'] as String).toLowerCase();
        final directionHe = (line['direction_he'] as String?)?.toLowerCase() ?? '';
        return number.contains(query) ||
               direction.contains(query) ||
               directionHe.contains(query);
      }).toList();
    }

    // Filter by operator
    if (operator != null && operator.isNotEmpty) {
      lines = lines.where((line) => line['operator'] == operator).toList();
    }

    _sendJson(request.response, {'lines': lines.take(limit).toList()});
  }

  // GET /line/{id} - Get line details with stops
  Future<void> _handleGetLine(HttpRequest request) async {
    final pathParts = request.uri.path.split('/');
    if (pathParts.length < 3) {
      _sendError(request.response, 400, 'INVALID_PARAMS', 'Missing line ID');
      return;
    }
    final lineId = pathParts[2];

    final params = request.uri.queryParameters;
    final direction = int.tryParse(params['direction'] ?? '0') ?? 0;

    final allLines = _linesData['lines'] as List;
    final line = allLines.firstWhere(
      (l) => l['id'] == lineId,
      orElse: () => null,
    );

    if (line == null) {
      _sendError(request.response, 404, 'NOT_FOUND', 'Line not found');
      return;
    }

    // Return full line with stops
    _sendJson(request.response, line);
  }

  // GET /arrivals - Get real-time arrivals for a station
  Future<void> _handleGetArrivals(HttpRequest request) async {
    final params = request.uri.queryParameters;

    final stationId = params['station_id'];
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;

    if (stationId == null || stationId.isEmpty) {
      _sendError(request.response, 400, 'INVALID_PARAMS', 'Missing station_id parameter');
      return;
    }

    final arrivalsMap = _arrivalsData['arrivals_by_station'] as Map<String, dynamic>;
    final stationArrivals = arrivalsMap[stationId];

    if (stationArrivals == null) {
      // Return empty arrivals for unknown stations
      _sendJson(request.response, {
        'station_id': stationId,
        'station_name': 'Unknown Station',
        'arrivals': [],
      });
      return;
    }

    final arrivals = _generateDynamicArrivals(
        stationArrivals['arrivals'] as List).take(limit).toList();

    _sendJson(request.response, {
      'station_id': stationId,
      'station_name': stationArrivals['station_name'],
      'arrivals': arrivals,
    });
  }

  // POST /route - Calculate transit route
  Future<void> _handlePostRoute(HttpRequest request) async {
    final body = await utf8.decodeStream(request);
    Map<String, dynamic> requestData;

    try {
      requestData = jsonDecode(body);
    } catch (e) {
      _sendError(request.response, 400, 'INVALID_JSON', 'Invalid JSON body');
      return;
    }

    final origin = requestData['origin'];
    final destination = requestData['destination'];

    if (origin == null || destination == null) {
      _sendError(request.response, 400, 'INVALID_PARAMS',
          'Missing origin or destination');
      return;
    }

    final originLat = (origin['lat'] as num).toDouble();
    final originLon = (origin['lon'] as num).toDouble();
    final destLat = (destination['lat'] as num).toDouble();
    final destLon = (destination['lon'] as num).toDouble();

    // Generate mock route
    final now = DateTime.now();
    final departureTime = now.add(Duration(minutes: 5));
    final totalMinutes = 25 + _random.nextInt(30);
    final arrivalTime = departureTime.add(Duration(minutes: totalMinutes));

    final route = {
      'id': 'route_${_random.nextInt(1000)}',
      'total_duration_minutes': totalMinutes,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'transfers': 1,
      'walking_duration_minutes': 8,
      'legs': [
        {
          'type': 'walk',
          'duration_minutes': 3,
          'distance_meters': 250,
          'from': {
            'name': 'Origin',
            'location': {'lat': originLat, 'lon': originLon}
          },
          'to': {
            'name': 'Ben Gurion/Cemetery',
            'name_he': 'בן גוריון/בית העלמין',
            'location': {'lat': 32.0858, 'lon': 34.7815}
          }
        },
        {
          'type': 'transit',
          'duration_minutes': totalMinutes - 8,
          'line': {
            'id': '273',
            'number': '273',
            'operator': 'egged',
            'color': '#4CAF50'
          },
          'departure_time': departureTime.add(Duration(minutes: 3)).toIso8601String(),
          'arrival_time': arrivalTime.subtract(Duration(minutes: 5)).toIso8601String(),
          'stops_count': 12,
          'from': {
            'name': 'Ben Gurion/Cemetery',
            'name_he': 'בן גוריון/בית העלמין',
            'location': {'lat': 32.0858, 'lon': 34.7815}
          },
          'to': {
            'name': 'Arlozorov Terminal',
            'name_he': 'טרמינל ארלוזורוב',
            'location': {'lat': 32.0956, 'lon': 34.7875}
          }
        },
        {
          'type': 'walk',
          'duration_minutes': 5,
          'distance_meters': 400,
          'from': {
            'name': 'Arlozorov Terminal',
            'name_he': 'טרמינל ארלוזורוב',
            'location': {'lat': 32.0956, 'lon': 34.7875}
          },
          'to': {
            'name': 'Destination',
            'location': {'lat': destLat, 'lon': destLon}
          }
        }
      ]
    };

    // Add alternative route
    final altDeparture = departureTime.add(Duration(minutes: 10));
    final altTotalMinutes = totalMinutes + 5;
    final altArrival = altDeparture.add(Duration(minutes: altTotalMinutes));

    final altRoute = {
      'id': 'route_${_random.nextInt(1000)}_alt',
      'total_duration_minutes': altTotalMinutes,
      'departure_time': altDeparture.toIso8601String(),
      'arrival_time': altArrival.toIso8601String(),
      'transfers': 0,
      'walking_duration_minutes': 12,
      'legs': [
        {
          'type': 'walk',
          'duration_minutes': 5,
          'distance_meters': 400,
          'from': {
            'name': 'Origin',
            'location': {'lat': originLat, 'lon': originLon}
          },
          'to': {
            'name': 'Dizengoff Center',
            'name_he': 'דיזנגוף סנטר',
            'location': {'lat': 32.0775, 'lon': 34.7747}
          }
        },
        {
          'type': 'transit',
          'duration_minutes': altTotalMinutes - 12,
          'line': {
            'id': '5',
            'number': '5',
            'operator': 'dan',
            'color': '#2196F3'
          },
          'departure_time': altDeparture.add(Duration(minutes: 5)).toIso8601String(),
          'arrival_time': altArrival.subtract(Duration(minutes: 7)).toIso8601String(),
          'stops_count': 18,
          'from': {
            'name': 'Dizengoff Center',
            'name_he': 'דיזנגוף סנטר',
            'location': {'lat': 32.0775, 'lon': 34.7747}
          },
          'to': {
            'name': 'Near Destination',
            'location': {'lat': destLat - 0.002, 'lon': destLon - 0.001}
          }
        },
        {
          'type': 'walk',
          'duration_minutes': 7,
          'distance_meters': 550,
          'from': {
            'name': 'Near Destination',
            'location': {'lat': destLat - 0.002, 'lon': destLon - 0.001}
          },
          'to': {
            'name': 'Destination',
            'location': {'lat': destLat, 'lon': destLon}
          }
        }
      ]
    };

    _sendJson(request.response, {'routes': [route, altRoute]});
  }

  // GET /search - Search for places
  Future<void> _handleSearch(HttpRequest request) async {
    final params = request.uri.queryParameters;

    final query = params['q']?.toLowerCase();
    final limit = int.tryParse(params['limit'] ?? '10') ?? 10;

    if (query == null || query.length < 2) {
      _sendError(request.response, 400, 'INVALID_PARAMS',
          'Query must be at least 2 characters');
      return;
    }

    final results = <Map<String, dynamic>>[];

    // Search stations
    final allStations = _stationsData['stations'] as List;
    for (final station in allStations) {
      final name = (station['name'] as String).toLowerCase();
      final nameHe = (station['name_he'] as String?)?.toLowerCase() ?? '';

      if (name.contains(query) || nameHe.contains(query)) {
        results.add({
          'id': 'station_${station['id']}',
          'type': 'station',
          'name': station['name'],
          'name_he': station['name_he'],
          'address': '${station['name']}, Tel Aviv',
          'location': station['location'],
        });
      }
    }

    // Add some mock address results
    if ('dizengoff'.contains(query) || query.contains('dizengoff')) {
      results.add({
        'id': 'address_1',
        'type': 'address',
        'name': 'Dizengoff Street 50',
        'name_he': 'רחוב דיזנגוף 50',
        'address': 'Dizengoff St 50, Tel Aviv',
        'location': {'lat': 32.0780, 'lon': 34.7740},
      });
    }

    if ('rothschild'.contains(query) || query.contains('rothschild')) {
      results.add({
        'id': 'address_2',
        'type': 'address',
        'name': 'Rothschild Boulevard',
        'name_he': 'שדרות רוטשילד',
        'address': 'Rothschild Blvd, Tel Aviv',
        'location': {'lat': 32.0638, 'lon': 34.7707},
      });
    }

    _sendJson(request.response, {'results': results.take(limit).toList()});
  }

  // Generate arrivals with dynamic times relative to now
  List<Map<String, dynamic>> _generateDynamicArrivals(List arrivals) {
    final now = DateTime.now();

    return arrivals.map((arrival) {
      final arrivalCopy = Map<String, dynamic>.from(arrival);
      final minutesUntil = arrival['minutes_until'] as int;

      // Add some randomness to make it feel real-time
      final adjustedMinutes = minutesUntil + _random.nextInt(3) - 1;
      final arrivalTime = now.add(Duration(minutes: adjustedMinutes.clamp(1, 60)));

      arrivalCopy['arrival_time'] = arrivalTime.toIso8601String();
      arrivalCopy['minutes_until'] = adjustedMinutes.clamp(1, 60);

      // Add next arrival for scheduled times
      if (!(arrival['is_realtime'] as bool)) {
        final nextArrival = arrivalTime.add(Duration(minutes: 15 + _random.nextInt(15)));
        arrivalCopy['next_arrival_time'] = nextArrival.toIso8601String();
      }

      return arrivalCopy;
    }).toList();
  }

  // Calculate distance between two points in meters (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  void _sendJson(HttpResponse response, Map<String, dynamic> data) {
    response.headers.contentType = ContentType.json;
    response.statusCode = 200;
    response.write(jsonEncode(data));
    response.close();
  }

  void _sendError(HttpResponse response, int statusCode, String code, String message) {
    response.headers.contentType = ContentType.json;
    response.statusCode = statusCode;
    response.write(jsonEncode({
      'code': code,
      'message': message,
    }));
    response.close();
  }
}

Future<void> main(List<String> args) async {
  int port = 8080;
  int delay = 0;
  String errorMode = 'none';

  for (final arg in args) {
    if (arg.startsWith('--port=')) {
      port = int.tryParse(arg.substring(7)) ?? port;
    } else if (arg.startsWith('--delay=')) {
      delay = int.tryParse(arg.substring(8)) ?? delay;
    } else if (arg.startsWith('--error-mode=')) {
      errorMode = arg.substring(13);
    }
  }

  final server = MockServer(
    port: port,
    delayMs: delay,
    errorMode: errorMode,
  );

  await server.start();
}
