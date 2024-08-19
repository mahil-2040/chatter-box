import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({super.key, required this.lat, required this.lng});
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: const Text(
          'Current Location',
          style: TextStyle(
            // fontFamily: "Poppins",
            fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat!, lng!),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.chatter_box',
          ),
          MarkerLayer(markers: [
            Marker(
              point: LatLng(lat!, lng!),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: const Icon(
                Icons.location_pin,
                size: 50,
                color: Colors.red,
              ),
            ),
          ])
        ],
      ),
    );
  }
}
