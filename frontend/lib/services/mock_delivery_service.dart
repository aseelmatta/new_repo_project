// mock data service for debugging
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';

class MockDeliveryService {
  List<Delivery> getMockDeliveries() {
    return [
      Delivery(
        id: '1',
        pickupLocation: LatLng(37.3688, -122.0363),
        pickupAddress: '100 Mathilda Place, Sunnyvale',
        dropoffLocation: LatLng(37.4030, -122.0326),
        dropoffAddress: '2025 Stierlin Ct, Mountain View',
        status: 'pending',
        description: 'Small package',
      ),
      Delivery(
        id: '2',
        pickupLocation: LatLng(37.3328, -122.0353),
        pickupAddress: '1 Infinite Loop, Cupertino',
        dropoffLocation: LatLng(37.4221, -122.0841),
        dropoffAddress: '1600 Amphitheatre Pkwy, Mountain View',
        status: 'pending',
        description: 'Medium box',
      ),
      // Add more mock deliveries
    ];
  }
}