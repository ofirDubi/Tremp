import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'place.dart';

Future<List<Place>> queryToPlaces(String query) async {
  final http.Response response =
      await http.get(Uri.parse('https://photon.komoot.io/api/?q=$query'));
  final dynamic body = json.decode(utf8.decode(response.bodyBytes));

  // ignore: avoid_dynamic_calls
  final List<dynamic> features = body['features'] as List<dynamic>;
  print("[+] features: $features");
  return features
      .map((dynamic e) => Place.fromJson(e as Map<String, dynamic>))
      .toSet()
      .toList();
}

class SearchModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Place> _suggestions = history;
  List<Place> get suggestions => _suggestions;

  String _query = '';
  String get query => _query;

  Future<void> onQueryChanged(String query) async {
    if (query == _query) {
      return;
    }
    print('[+] search for string in map - $query');
    _query = query;
    _isLoading = true;
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();

    if (query.isEmpty) {
      _suggestions = history;
    } else {
      _suggestions = await queryToPlaces(query);
      // final http.Response response =
      //     await http.get(Uri.parse('https://photon.komoot.io/api/?q=$query'));
      // final dynamic body = json.decode(utf8.decode(response.bodyBytes));

      // // ignore: avoid_dynamic_calls
      // final List<dynamic> features = body['features'] as List<dynamic>;
      // print("[+] features: $features");
      // _suggestions = features
      //     .map((dynamic e) => Place.fromJson(e as Map<String, dynamic>))
      //     .toSet()
      //     .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _suggestions = history;
    notifyListeners();
  }
}

const List<Place> history = <Place>[
  Place(
    name: 'San Fracisco',
    country: 'United States of America',
    state: 'California',
  ),
  Place(
    name: 'Singapore',
    country: 'Singapore',
  ),
  Place(
    name: 'Munich',
    state: 'Bavaria',
    country: 'Germany',
  ),
  Place(
    name: 'London',
    country: 'United Kingdom',
  ),
];
