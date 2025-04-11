import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  final LatLng initialPosition;
  final double zoom;
  final bool showMyLocation;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Function(GoogleMapController)? onMapCreated;
  
  const MapView({
    Key? key,
    this.initialPosition = const LatLng(0, 0), // Default position
    this.zoom = 14.0,
    this.showMyLocation = true,
    this.markers,
    this.polylines,
    this.onMapCreated,
  }) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(0, 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.showMyLocation) {
      _getCurrentLocation();
    } else {
      setState(() {
        _currentPosition = widget.initialPosition;
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle permission denied
          setState(() {
            _currentPosition = widget.initialPosition;
            _isLoading = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Handle permanently denied permissions
        setState(() {
          _currentPosition = widget.initialPosition;
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, widget.zoom),
      );
    } catch (e) {
      setState(() {
        _currentPosition = widget.initialPosition;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.showMyLocation ? _currentPosition : widget.initialPosition,
            zoom: widget.zoom,
          ),
          myLocationEnabled: widget.showMyLocation,
          myLocationButtonEnabled: widget.showMyLocation,
          zoomControlsEnabled: true,
          mapType: MapType.normal,
          markers: widget.markers ?? {},
          polylines: widget.polylines ?? {},
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          },
        );
  }
}