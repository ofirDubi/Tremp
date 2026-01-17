import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tremp_app/place.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'server_comms.dart';
// Widget buildMyMap() {
//   // LatLng coords = searchedLocation.hasName
//   //     ? LatLng(searchedLocation.coordinates)
//   //     : const [51.509364, -0.128928];
//   return FlutterMap(
//     options: MapOptions(
//       initialCenter: LatLng(51.509364, -0.128928),
//       initialZoom: 9.2,
//     ),
//     children: [
//       TileLayer(
//         urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//         userAgentPackageName: 'com.example.app',
//       ),
//       RichAttributionWidget(
//         attributions: [
//           TextSourceAttribution(
//             'OpenStreetMap contributors',
//             onTap: () =>
//                 launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
//           ),
//         ],
//       ),
//     ],
//   );
// }

Widget buildMyMap2(MapController mapController, Place originLocation,
    Place destinationLocation, List<Station> visibleStations) {
  // LatLng coordinates = searchedLocation.hasName
  //     ? searchedLocation.coordinates
  //     : LatLng(51.509364, -0.128928);
  final PopupController _popupLayerController = PopupController();

  return FlutterMap(
    mapController: mapController,
    options: MapOptions(
      initialCenter: LatLng(51.509364, -0.128928),
      initialZoom: 9.2,
      onTap: (_, p) {
        print("[+] clicked on $p");
        _popupLayerController.hideAllPopups();
      },
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),
      MarkerLayer(markers: [
        buildPin(originLocation.coordinates, Colors.black),
        buildPin(destinationLocation.coordinates, Colors.green.shade700)
      ]),
      // wrap stations in marker layout with gesture decoration which prints to console on tap
      // GestureDetector(
      //   onTap: () => print("[+] clicked on station"),
      //   child: MarkerLayer(
      //       markers: visible_stations.map((station) {
      //     return buildStationPin(station);
      //   }).toList()),
      // ),
      PopupMarkerLayer(
        options: PopupMarkerLayerOptions(
          markers: visibleStations.map((station) {
            return StationMarker(station: station);
          }).toList(),
          popupController: _popupLayerController,
          popupDisplayOptions: PopupDisplayOptions(
            builder: (_, Marker marker) {
              if (marker is StationMarker) {
                return StationMarkerPopup(station: marker.station);
              }
              return const Card(child: Text('Not a station'));
            },
          ),
        ),
      ),
      // PopupMarkerLayer(

      //     markers: visible_stations.map((station) {
      //   return buildPin(station.coordinates, Colors.red.shade700);
      // }).toList()),
      RichAttributionWidget(
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () =>
                launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
          ),
        ],
      ),
    ],
  );
}

Marker buildPin(LatLng point, Color c) => Marker(
      point: point,
      width: 60,
      height: 60,
      child: Icon(Icons.location_pin, size: 60, color: c),
    );

class StationMarker extends Marker {
  final Station station;
  StationMarker({required this.station})
      : super(
          point: station.coordinates,
          width: 60,
          height: 60,
          child: Icon(Icons.location_pin, size: 60, color: Colors.red.shade700),
        );
}

class StationMarkerPopup extends StatelessWidget {
  final Station station;
  const StationMarkerPopup({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Image.network(monument.imagePath, width: 200),
            Text(station.name),
            Text('${station.coordinates}'),
          ],
        ),
      ),
    );
  }
}

Marker buildStationPin(Station station) => Marker(
      point: station.coordinates,
      width: 60,
      height: 60,
      child: Icon(Icons.location_pin, size: 60, color: Colors.red.shade700),
    );
