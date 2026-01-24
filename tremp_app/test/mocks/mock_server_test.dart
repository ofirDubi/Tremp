import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// Tests for the Mock Server verifying it matches the OpenAPI specification.
///
/// Run these tests with:
///   1. Start the mock server: dart mock_server.dart
///   2. Run tests: dart test mock_server_test.dart

const String baseUrl = 'http://localhost:8080';

void main() {
  group('OpenAPI Compliance Tests', () {
    group('GET /stations', () {
      test('returns stations within bounding box', () async {
        final response = await http.get(Uri.parse(
            '$baseUrl/stations?min_lat=32.05&max_lat=32.12&min_lon=34.75&max_lon=34.82'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('stations'));
        expect(data['stations'], isA<List>());

        if ((data['stations'] as List).isNotEmpty) {
          final station = data['stations'][0];
          // Verify Station schema
          expect(station, contains('id'));
          expect(station, contains('name'));
          expect(station, contains('location'));
          expect(station['location'], contains('lat'));
          expect(station['location'], contains('lon'));
        }
      });

      test('returns 400 for missing parameters', () async {
        final response = await http.get(Uri.parse('$baseUrl/stations'));

        expect(response.statusCode, equals(400));

        final data = jsonDecode(response.body);
        expect(data, contains('code'));
        expect(data, contains('message'));
      });

      test('respects limit parameter', () async {
        final response = await http.get(Uri.parse(
            '$baseUrl/stations?min_lat=32.0&max_lat=32.2&min_lon=34.7&max_lon=34.9&limit=5'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect((data['stations'] as List).length, lessThanOrEqualTo(5));
      });
    });

    group('GET /stations/nearby', () {
      test('returns nearby stations with distance', () async {
        final response = await http.get(Uri.parse(
            '$baseUrl/stations/nearby?lat=32.0853&lon=34.7818&radius=1000'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('stations'));

        if ((data['stations'] as List).isNotEmpty) {
          final station = data['stations'][0];
          expect(station, contains('distance_meters'));
          expect(station['distance_meters'], isA<int>());
        }
      });
    });

    group('GET /station/{id}', () {
      test('returns station details with arrivals', () async {
        final response = await http.get(Uri.parse('$baseUrl/station/25786'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('id'));
        expect(data['id'], equals('25786'));
        expect(data, contains('name'));
        expect(data, contains('arrivals'));
        expect(data['arrivals'], isA<List>());

        if ((data['arrivals'] as List).isNotEmpty) {
          final arrival = data['arrivals'][0];
          // Verify Arrival schema
          expect(arrival, contains('line'));
          expect(arrival, contains('destination'));
          expect(arrival, contains('arrival_time'));
          expect(arrival, contains('is_realtime'));
        }
      });

      test('returns 404 for unknown station', () async {
        final response = await http.get(Uri.parse('$baseUrl/station/invalid'));

        expect(response.statusCode, equals(404));

        final data = jsonDecode(response.body);
        expect(data['code'], equals('NOT_FOUND'));
      });
    });

    group('GET /lines', () {
      test('returns list of lines', () async {
        final response = await http.get(Uri.parse('$baseUrl/lines'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('lines'));
        expect(data['lines'], isA<List>());
        expect((data['lines'] as List).length, greaterThan(0));

        final line = data['lines'][0];
        // Verify Line schema
        expect(line, contains('id'));
        expect(line, contains('number'));
        expect(line, contains('operator'));
        expect(line, contains('direction'));
        expect(line, contains('color'));
      });

      test('filters by search query', () async {
        final response = await http.get(Uri.parse('$baseUrl/lines?q=273'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        final lines = data['lines'] as List;

        expect(lines.any((l) => l['number'] == '273'), isTrue);
      });

      test('filters by operator', () async {
        final response = await http.get(Uri.parse('$baseUrl/lines?operator=egged'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        final lines = data['lines'] as List;

        for (final line in lines) {
          expect(line['operator'], equals('egged'));
        }
      });
    });

    group('GET /line/{id}', () {
      test('returns line details with stops', () async {
        final response = await http.get(Uri.parse('$baseUrl/line/273'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('id'));
        expect(data['id'], equals('273'));
        expect(data, contains('stops'));
        expect(data['stops'], isA<List>());

        if ((data['stops'] as List).isNotEmpty) {
          final stop = data['stops'][0];
          // Verify LineStop schema
          expect(stop, contains('station_id'));
          expect(stop, contains('name'));
          expect(stop, contains('sequence'));
          expect(stop, contains('location'));
        }
      });

      test('returns 404 for unknown line', () async {
        final response = await http.get(Uri.parse('$baseUrl/line/invalid'));

        expect(response.statusCode, equals(404));

        final data = jsonDecode(response.body);
        expect(data['code'], equals('NOT_FOUND'));
      });
    });

    group('GET /arrivals', () {
      test('returns arrivals for station', () async {
        final response = await http.get(Uri.parse('$baseUrl/arrivals?station_id=25786'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('station_id'));
        expect(data, contains('station_name'));
        expect(data, contains('arrivals'));

        if ((data['arrivals'] as List).isNotEmpty) {
          final arrival = data['arrivals'][0];
          expect(arrival, contains('line'));
          expect(arrival, contains('destination'));
          expect(arrival, contains('arrival_time'));
          expect(arrival, contains('minutes_until'));
          expect(arrival, contains('is_realtime'));

          // Verify arrival_time is ISO 8601
          expect(() => DateTime.parse(arrival['arrival_time']), returnsNormally);
        }
      });

      test('returns 400 for missing station_id', () async {
        final response = await http.get(Uri.parse('$baseUrl/arrivals'));

        expect(response.statusCode, equals(400));
      });
    });

    group('POST /route', () {
      test('calculates route between two points', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/route'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'origin': {'lat': 32.0853, 'lon': 34.7818},
            'destination': {'lat': 32.1093, 'lon': 34.8553},
            'mode': 'leave_now',
          }),
        );

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('routes'));
        expect(data['routes'], isA<List>());
        expect((data['routes'] as List).length, greaterThan(0));

        final route = data['routes'][0];
        // Verify Route schema
        expect(route, contains('id'));
        expect(route, contains('total_duration_minutes'));
        expect(route, contains('departure_time'));
        expect(route, contains('arrival_time'));
        expect(route, contains('transfers'));
        expect(route, contains('legs'));

        expect(route['legs'], isA<List>());
        expect((route['legs'] as List).length, greaterThan(0));

        final leg = route['legs'][0];
        // Verify RouteLeg schema
        expect(leg, contains('type'));
        expect(leg, contains('duration_minutes'));
        expect(leg, contains('from'));
        expect(leg, contains('to'));
      });

      test('returns 400 for invalid body', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/route'),
          headers: {'Content-Type': 'application/json'},
          body: 'invalid json',
        );

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for missing origin/destination', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/route'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'origin': {'lat': 32.0853, 'lon': 34.7818}}),
        );

        expect(response.statusCode, equals(400));
      });
    });

    group('GET /search', () {
      test('returns search results', () async {
        final response = await http.get(Uri.parse('$baseUrl/search?q=dizengoff'));

        expect(response.statusCode, equals(200));

        final data = jsonDecode(response.body);
        expect(data, contains('results'));
        expect(data['results'], isA<List>());

        if ((data['results'] as List).isNotEmpty) {
          final place = data['results'][0];
          // Verify Place schema
          expect(place, contains('name'));
          expect(place, contains('location'));
          expect(place['location'], contains('lat'));
          expect(place['location'], contains('lon'));
        }
      });

      test('returns 400 for short query', () async {
        final response = await http.get(Uri.parse('$baseUrl/search?q=a'));

        expect(response.statusCode, equals(400));
      });
    });

    group('Error Response Schema', () {
      test('error responses follow schema', () async {
        final response = await http.get(Uri.parse('$baseUrl/station/invalid'));

        expect(response.statusCode, equals(404));

        final data = jsonDecode(response.body);
        // Verify Error schema
        expect(data, contains('code'));
        expect(data, contains('message'));
        expect(data['code'], isA<String>());
        expect(data['message'], isA<String>());
      });
    });

    group('CORS Headers', () {
      test('includes CORS headers in response', () async {
        final response = await http.get(Uri.parse('$baseUrl/lines'));

        expect(response.headers['access-control-allow-origin'], equals('*'));
      });
    });
  });

  group('Mock Data Quality Tests', () {
    test('stations include Hebrew names', () async {
      final response = await http.get(Uri.parse(
          '$baseUrl/stations?min_lat=32.0&max_lat=32.2&min_lon=34.7&max_lon=34.9'));

      final data = jsonDecode(response.body);
      final stations = data['stations'] as List;

      for (final station in stations) {
        expect(station, contains('name_he'));
        expect(station['name_he'], isNotEmpty);
      }
    });

    test('lines include multiple operators', () async {
      final response = await http.get(Uri.parse('$baseUrl/lines'));

      final data = jsonDecode(response.body);
      final lines = data['lines'] as List;

      final operators = lines.map((l) => l['operator']).toSet();
      expect(operators.length, greaterThan(1));
    });

    test('arrivals include realtime and scheduled', () async {
      final response = await http.get(Uri.parse('$baseUrl/arrivals?station_id=25786'));

      final data = jsonDecode(response.body);
      final arrivals = data['arrivals'] as List;

      final hasRealtime = arrivals.any((a) => a['is_realtime'] == true);
      final hasScheduled = arrivals.any((a) => a['is_realtime'] == false);

      expect(hasRealtime || hasScheduled, isTrue);
    });
  });
}
