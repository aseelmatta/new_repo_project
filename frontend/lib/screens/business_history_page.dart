import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';

class BusinessHistoryPage extends StatefulWidget {
  const BusinessHistoryPage({super.key});

  @override
  State<BusinessHistoryPage> createState() => _BusinessHistoryPageState();
}

class _BusinessHistoryPageState extends State<BusinessHistoryPage> {

  List<Delivery> _deliveries = [];
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    final resp = await DeliveryService.getDeliveries();
    final all = resp.success ? resp.data! : <Delivery>[];
    final history = all
        .where((d) => d.status == 'completed' || d.status == 'cancelled')
        .toList();
    setState(() {
      _deliveries = history;
    });
  }


  List<Delivery> get _filteredDeliveries {
    var filtered = _deliveries.where((delivery) {
      bool matchesSearch = delivery.pickupAddress
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          delivery.dropoffAddress
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          delivery.id.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = _statusFilter == 'all' || delivery.status == _statusFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort the results
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.id.compareTo(b.id)); // Mock sort by ID as date
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      // Add more sorting options as needed
    }

    return filtered;
  }

  void _showDeliveryDetails(Delivery delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery #${delivery.id}',
                    style: Theme.of(context).textTheme.titleLarge),
                Chip(
                  label: Text(delivery.status),
                  backgroundColor: _getStatusColor(delivery.status),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            _buildInfoSection('Delivery Details'),
            _buildInfoRow('Pickup:', delivery.pickupAddress),
            _buildInfoRow('Dropoff:', delivery.dropoffAddress),
            _buildInfoRow('Description:', delivery.description),
            _buildInfoRow('Date Created:', 'May 20, 2025 - 14:30'),
            
            if (delivery.status == 'completed') ...[
              _buildInfoRow('Delivered At:', 'May 20, 2025 - 16:45'),
              _buildInfoRow('Delivery Time:', '2h 15min'),
              _buildInfoRow('Courier:', 'John Doe'),
              _buildInfoRow('Rating Given:', '4.5 ★'),
            ] else if (delivery.status == 'cancelled') ...[
              _buildInfoRow('Cancelled At:', 'May 20, 2025 - 15:00'),
              _buildInfoRow('Reason:', 'Business request'),
              _buildInfoRow('Refund Status:', 'Processed'),
            ],
            
            const SizedBox(height: 24),
            Row(
              children: [
                if (delivery.status == 'completed') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Download receipt
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Receipt'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Reorder delivery
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reorder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
                if (delivery.status == 'cancelled')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Recreate delivery
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Similar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeliveries = _filteredDeliveries;
    final completedCount = _deliveries.where((d) => d.status == 'completed').length;
    final cancelledCount = _deliveries.where((d) => d.status == 'cancelled').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_desc',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'date_asc',
                child: Text('Oldest First'),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Statistics
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'History Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Completed', completedCount, Colors.green),
                      _buildStatCard('Cancelled', cancelledCount, Colors.red),
                      _buildStatCard('Total', completedCount + cancelledCount, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search deliveries...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Delivery History List
          Expanded(
            child: filteredDeliveries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No delivery history found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = filteredDeliveries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(delivery.status),
                            child: Icon(
                              delivery.status == 'completed' 
                                  ? Icons.check 
                                  : Icons.cancel,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('Delivery #${delivery.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To: ${delivery.dropoffAddress}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'May 20, 2025',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    delivery.status == 'completed' 
                                        ? '★ 4.5' 
                                        : 'Cancelled',
                                    style: TextStyle(
                                      color: delivery.status == 'completed' 
                                          ? Colors.amber 
                                          : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          isThreeLine: true,
                          onTap: () => _showDeliveryDetails(delivery),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}