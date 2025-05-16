import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';
import '../services/mock_delivery_service.dart';

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  final MockDeliveryService _deliveryService = MockDeliveryService();
  List<Delivery> _deliveries = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  void _loadDeliveries() {
    setState(() {
      _deliveries = _deliveryService.getMockDeliveries();
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
            Text('Delivery ID: ${delivery.id}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Pickup: ${delivery.pickupAddress}'),
            Text('Dropoff: ${delivery.dropoffAddress}'),
            Text('Status: ${delivery.status}'),
            Text('Description: ${delivery.description}'),
            const SizedBox(height: 16),
            if (delivery.status != 'completed' && delivery.status != 'cancelled')
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement live tracking
                },
                child: const Text('Track Delivery'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeliveries = _deliveries.where((delivery) =>
        delivery.pickupAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        delivery.dropoffAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        delivery.status.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search deliveries...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredDeliveries.length,
              itemBuilder: (context, index) {
                final delivery = filteredDeliveries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('Delivery to ${delivery.dropoffAddress}'),
                    subtitle: Text('Status: ${delivery.status}'),
                    trailing: Icon(
                      _getStatusIcon(delivery.status),
                      color: _getStatusColor(delivery.status),
                    ),
                    onTap: () => _showDeliveryDetails(delivery),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // TODO: Navigate to create delivery page
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                // TODO: Navigate to chatbot page
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                // TODO: Navigate to profile page
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'in_progress':
        return Icons.local_shipping;
      case 'accepted':
        return Icons.thumb_up;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
