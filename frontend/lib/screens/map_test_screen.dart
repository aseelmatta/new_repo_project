import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/maps/map_view.dart';
import 'package:geolocator/geolocator.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({Key? key}) : super(key: key);

  @override
  _MapTestScreenState createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  Set<Marker> _markers = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MapView(
              showMyLocation: true,
              markers: _markers,
              onMapCreated: (controller) {
                // You can do something with the controller here
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Example of adding a marker at the current position
                _addMarker();
              },
              child: const Text('Add Marker at Current Location'),
            ),
          ),
        ],
      ),
    );
  }

  void _addMarker() async {
    final position = await Geolocator.getCurrentPosition();
    final marker = Marker(
      markerId: MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(
        title: 'Current Location',
        snippet: 'You are here',
      ),
    );
    
    setState(() {
      _markers = {marker};
    });
  }
}