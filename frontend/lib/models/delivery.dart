import 'package:google_maps_flutter/google_maps_flutter.dart';

class Delivery {
  final String id;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng dropoffLocation;
  final String dropoffAddress;
  final String status; // pending, accepted, in_progress, completed, cancelled
  final String description; //might not need it
  
  Delivery({
    required this.id,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropoffLocation,
    required this.dropoffAddress,
    required this.status,
    required this.description,//might remove later?
  });
}