// Enhanced mock data service for demo with trackable deliveries
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';

class MockDeliveryService {
  List<Delivery> getMockDeliveries() {
    return [
      // TRACKABLE DELIVERIES - These will show "Track Live" button
      Delivery(
        id: 'DEMO001',
        pickupLocation: LatLng(37.4219999, -122.0840575), // Google HQ
        pickupAddress: '1600 Amphitheatre Pkwy, Mountain View, CA',
        dropoffLocation: LatLng(37.4030, -122.0326),
        dropoffAddress: '2025 Stierlin Ct, Mountain View, CA',
        status: 'accepted', // ✅ This will show Track Live button
        description: 'Demo Package - Laptop Computer',
        recipientName: 'John Smith',
        recipientPhone: '+1 (555) 123-4567',
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
        instructions: 'Handle with care - fragile electronics',
      ),
      
      Delivery(
        id: 'DEMO002',
        pickupLocation: LatLng(37.3688, -122.0363),
        pickupAddress: '100 Mathilda Place, Sunnyvale, CA',
        dropoffLocation: LatLng(37.4419, -122.1430),
        dropoffAddress: '1 Hacker Way, Menlo Park, CA',
        status: 'in_progress', // ✅ This will show Track Live button  
        description: 'Demo Package - Important Documents',
        recipientName: 'Sarah Johnson',
        recipientPhone: '+1 (555) 987-6543',
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        instructions: 'Deliver to front desk reception',
      ),

      // COMPLETED DELIVERY - For history demonstration
      Delivery(
        id: 'DEMO003',
        pickupLocation: LatLng(37.3328, -122.0353),
        pickupAddress: '1 Infinite Loop, Cupertino, CA',
        dropoffLocation: LatLng(37.4221, -122.0841),
        dropoffAddress: '1600 Amphitheatre Pkwy, Mountain View, CA',
        status: 'completed',
        description: 'Demo Package - Marketing Materials',
        recipientName: 'Mike Chen',
        recipientPhone: '+1 (555) 456-7890',
        createdAt: DateTime.now().subtract(Duration(hours: 4)),
        instructions: 'Leave at security if no one available',
      ),

      // PENDING DELIVERY - For creation flow demonstration  
      Delivery(
        id: 'DEMO004',
        pickupLocation: LatLng(37.3861, -122.0839),
        pickupAddress: '899 Cherry Ave, San Bruno, CA',
        dropoffLocation: LatLng(37.4043, -122.0748),
        dropoffAddress: '333 Middlefield Rd, Menlo Park, CA',
        status: 'pending',
        description: 'Demo Package - Office Supplies',
        recipientName: 'Lisa Rodriguez',
        recipientPhone: '+1 (555) 234-5678',
        createdAt: DateTime.now().subtract(Duration(minutes: 10)),
        instructions: 'Call recipient before delivery',
      ),

      // CANCELLED DELIVERY - For edge case demonstration
      Delivery(
        id: 'DEMO005',
        pickupLocation: LatLng(37.4024, -122.0519),
        pickupAddress: '1065 La Avenida St, Mountain View, CA',
        dropoffLocation: LatLng(37.3874, -122.0575),
        dropoffAddress: '650 Castro St, Mountain View, CA',
        status: 'cancelled',
        description: 'Demo Package - Cancelled Order',
        recipientName: 'David Kim',
        recipientPhone: '+1 (555) 345-6789',
        createdAt: DateTime.now().subtract(Duration(hours: 2)),
        instructions: 'Order cancelled by customer',
      ),
    ];
  }

  // Method to simulate delivery status progression for demo
  Delivery updateDeliveryStatus(Delivery delivery, String newStatus) {
    return delivery.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Get deliveries by status for filtering
  List<Delivery> getDeliveriesByStatus(String status) {
    return getMockDeliveries().where((delivery) => delivery.status == status).toList();
  }

  // Get trackable deliveries (accepted or in_progress)
  List<Delivery> getTrackableDeliveries() {
    return getMockDeliveries().where((delivery) => 
        delivery.status == 'accepted' || delivery.status == 'in_progress').toList();
  }

  // Demo method to create a new delivery with immediate acceptance
  Delivery createDemoDelivery({
    required String pickupAddress,
    required String dropoffAddress,
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    String description = 'Demo Package',
  }) {
    return Delivery(
      id: 'DEMO${DateTime.now().millisecondsSinceEpoch}',
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      dropoffLocation: dropoffLocation,
      dropoffAddress: dropoffAddress,
      status: 'accepted', // Immediately trackable for demo
      description: description,
      recipientName: 'Demo Recipient',
      recipientPhone: '+1 (555) 000-0000',
      createdAt: DateTime.now(),
      instructions: 'Demo delivery for testing',
    );
  }
}