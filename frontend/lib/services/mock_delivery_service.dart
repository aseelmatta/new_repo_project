// mock data service for debugging
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';

class MockDeliveryService {
  List<Delivery> getMockDeliveries() {
    return [
      Delivery(
        id: '1',
        pickupLocation: LatLng(33.8463, 35.9022),
        pickupAddress: '123 Main St, Beirut',
        dropoffLocation: LatLng(33.8932, 35.5016),
        dropoffAddress: '456 Park Ave, Beirut',
        status: 'pending',
        description: 'Small package',
      ),
      Delivery(
        id: '2',
        pickupLocation: LatLng(33.8561, 35.8989),
        pickupAddress: '789 Cedar Rd, Beirut',
        dropoffLocation: LatLng(33.9015, 35.4878),
        dropoffAddress: '101 Pine St, Beirut',
        status: 'pending',
        description: 'Medium box',
      ),
      // Add more mock deliveries
    ];
  }
}