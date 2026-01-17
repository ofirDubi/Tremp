import 'dart:convert';
// import 'package:flutter_country_restapi/app/data/model/country_model.dart';
import "package:universal_html/html.dart";
import 'package:universal_html/controller.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

List<Station> stationFromJson(String str) =>
    List<Station>.from(json.decode(str).map((x) => Station.fromJson(x)));

String stationToJson(Station data) => json.encode(data.toJson());

// To parse this JSON data, do
//
//     final stationRequest = stationRequestFromJson(jsonString);
class Station {
  String stations;
  String stopCode;
  String stopName;
  String stopDesc;
  String stopLat;
  String stopLon;
  String locationType;
  String parentStation;
  String zoneId;

  Station({
    required this.stations,
    required this.stopCode,
    required this.stopName,
    required this.stopDesc,
    required this.stopLat,
    required this.stopLon,
    required this.locationType,
    required this.parentStation,
    required this.zoneId,
  });

  LatLng get coordinates =>
      LatLng(double.parse(stopLat), double.parse(stopLon));

  String get name => "${stopName}, {$stopCode}, {$stopDesc}";

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        stations: json["stations"],
        stopCode: json["stop_code"],
        stopName: json["stop_name"],
        stopDesc: json["stop_desc"],
        stopLat: json["stop_lat"],
        stopLon: json["stop_lon"],
        locationType: json["location_type"],
        parentStation: json["parent_station"],
        zoneId: json["zone_id"],
      );

  Map<String, dynamic> toJson() => {
        "stations": stations,
        "stop_code": stopCode,
        "stop_name": stopName,
        "stop_desc": stopDesc,
        "stop_lat": stopLat,
        "stop_lon": stopLon,
        "location_type": locationType,
        "parent_station": parentStation,
        "zone_id": zoneId,
      };
}

class StationApi {
  Future<List<Station>>? getAllStationsInArea(
      LatLng top_right, LatLng bottom_left) async {
    // var client = http.Client();
    // Client
    final controller = WindowController();
    List<Station> stations_list = [];
    // controller.defaultHttpClient.userAgent = 'My Hacker News client';
    var uri = Uri.parse(
        'http://127.0.0.1:8000/stations?min_lon=${bottom_left.longitude}&max_lon=${top_right.longitude}&min_lat=${bottom_left.latitude}&max_lat=${top_right.latitude}');
    int statusCode = 0;
    print("[+] sending request to server from uri - ${uri}!");
    await controller.openHttp(
      method: 'GET',
      uri: uri,
      onRequest: (HttpClientRequest request) {
        // Add custom headers
        request.headers.set('Authorization', 'TestTokenA1B2C5');
        // request.cookies.add(Cookie('cookieName', 'cookieValue'));
      },
      onResponse: (HttpClientResponse response) {
        print('Status code: ${response.statusCode}');
        print(response.transform(utf8.decoder).join());
        statusCode = response.statusCode;

        // if(response.statusCode != 200){
        //   stationsListData = response.transform(utf8.decoder).join();
        // }
      },
    );
    if (statusCode != 200) {
      return [];
    }
    String resp = controller.window.document.text ?? "";
    stations_list = stationFromJson(resp);

    // add auth token to request
    // print("[+] sending request to server from uri - ${uri}!");
    // var response = await client.get(
    //   uri,
    //   headers: {HttpHeaders.authorizationHeader: "TestTokenA1B2C5"},
    // );
    // if (response.statusCode == 200) {
    //   return stationFromJson(const Utf8Decoder().convert(response.bodyBytes));
    // } else {
    //   // print response to cnoosle
    //   print("[-] failed to get stations!");
    //   print(response.body);
    //   return null;
    // }
    return stations_list;
  }
}
