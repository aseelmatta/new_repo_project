import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';
import '../services/mock_delivery_service.dart';

class CourierDashboard extends StatefulWidget {
  const CourierDashboard({super.key});

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  final MockDeliveryService _deliveryService = MockDeliveryService();
  List<Delivery> _availableDeliveries = [];
  List<Delivery> _myDeliveries = [];
  bool _showMapView = false;
  String _courierStatus = 'available';
  GoogleMapController? _mapController;
  final LatLng _courierLocation = const LatLng(37.4219999, -122.0840575); // Mock location

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  void _loadDeliveries() {
    setState(() {
      _availableDeliveries = _deliveryService.getMockDeliveries();
    });
  }

  void _showDeliveryDetails(Delivery delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Details', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Pickup: ${delivery.pickupAddress}'),
            Text('Dropoff: ${delivery.dropoffAddress}'),
            Text('Description: ${delivery.description}'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement accept delivery
                    setState(() {
                      _myDeliveries.add(delivery);
                      _availableDeliveries.remove(delivery);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Accept Delivery'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courier Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String status) {
              setState(() {
                _courierStatus = status;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'available',
                child: Text('Available'),
              ),
              const PopupMenuItem(
                value: 'busy',
                child: Text('Busy'),
              ),
              const PopupMenuItem(
                value: 'away',
                child: Text('Away'),
              ),
            ],
            child: Chip(
              label: Text(_courierStatus),
              backgroundColor: _courierStatus == 'available' 
                  ? Colors.green 
                  : _courierStatus == 'busy' 
                      ? Colors.orange 
                      : Colors.grey,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showMapView = false;
                    });
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('List View'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showMapView = true;
                    });
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Map View'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showMapView
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _courierLocation,
                      zoom: 12,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('courier'),
                        position: _courierLocation,
                        infoWindow: const InfoWindow(title: 'Your Location'),
                      ),
                      ..._availableDeliveries.map(
                        (delivery) => Marker(
                          markerId: MarkerId(delivery.id),
                          position: delivery.pickupLocation,
                          infoWindow: InfoWindow(
                            title: 'Pickup: ${delivery.pickupAddress}',
                            snippet: 'Tap for details',
                          ),
                          onTap: () => _showDeliveryDetails(delivery),
                        ),
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  )
                : ListView.builder(
                    itemCount: _availableDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = _availableDeliveries[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('Delivery #${delivery.id}'),
                          subtitle: Text(
                            'From: ${delivery.pickupAddress}\nTo: ${delivery.dropoffAddress}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () => _showDeliveryDetails(delivery),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // TODO: Implement navigation
        },
      ),
    );
  }
}
