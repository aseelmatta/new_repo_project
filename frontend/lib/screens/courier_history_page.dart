import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/delivery.dart';
import '../services/mock_delivery_service.dart';

class CourierHistoryPage extends StatefulWidget {
  const CourierHistoryPage({super.key});

  @override
  State<CourierHistoryPage> createState() => _CourierHistoryPageState();
}

class _CourierHistoryPageState extends State<CourierHistoryPage> {
  final MockDeliveryService _deliveryService = MockDeliveryService();
  List<Delivery> _deliveries = [];
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'date_desc';
  String _timeFilter = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _loadCourierDeliveries();
  }

  void _loadCourierDeliveries() {
    setState(() {
      // For demo, we'll show completed and cancelled deliveries as courier history
      _deliveries = _deliveryService.getMockDeliveries()
          .where((delivery) => 
              delivery.status == 'completed' || delivery.status == 'cancelled')
          .toList();
      
      // Add some mock courier-specific data
      _deliveries.addAll([
        Delivery(
          id: 'HIST001',
          pickupLocation: LatLng(37.4419, -122.1430),
          pickupAddress: '1 Hacker Way, Menlo Park, CA',
          dropoffLocation: LatLng(37.4030, -122.0326),
          dropoffAddress: '2025 Stierlin Ct, Mountain View, CA',
          status: 'completed',
          description: 'Electronics Package',
          recipientName: 'Alex Thompson',
          recipientPhone: '+1 (555) 111-2222',
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          instructions: 'Delivered successfully',
        ),
        Delivery(
          id: 'HIST002',
          pickupLocation: LatLng(37.3861, -122.0839),
          pickupAddress: '899 Cherry Ave, San Bruno, CA',
          dropoffLocation: LatLng(37.4043, -122.0748),
          dropoffAddress: '333 Middlefield Rd, Menlo Park, CA',
          status: 'completed',
          description: 'Food Delivery',
          recipientName: 'Maria Garcia',
          recipientPhone: '+1 (555) 333-4444',
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          instructions: 'Left at front door as requested',
        ),
        Delivery(
          id: 'HIST003',
          pickupLocation: LatLng(37.4024, -122.0519),
          pickupAddress: '1065 La Avenida St, Mountain View, CA',
          dropoffLocation: LatLng(37.3874, -122.0575),
          dropoffAddress: '650 Castro St, Mountain View, CA',
          status: 'completed',
          description: 'Document Envelope',
          recipientName: 'Robert Wilson',
          recipientPhone: '+1 (555) 555-6666',
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          instructions: 'Signed by recipient',
        ),
      ]);
    });
  }

  List<Delivery> get _filteredDeliveries {
    var filtered = _deliveries.where((delivery) {
      bool matchesSearch = delivery.recipientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false ||
          delivery.pickupAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          delivery.dropoffAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          delivery.id.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = _statusFilter == 'all' || delivery.status == _statusFilter;
      
      bool matchesTime = true;
      if (_timeFilter != 'all' && delivery.createdAt != null) {
        DateTime now = DateTime.now();
        switch (_timeFilter) {
          case 'today':
            matchesTime = delivery.createdAt!.day == now.day && 
                         delivery.createdAt!.month == now.month &&
                         delivery.createdAt!.year == now.year;
            break;
          case 'week':
            matchesTime = now.difference(delivery.createdAt!).inDays <= 7;
            break;
          case 'month':
            matchesTime = now.difference(delivery.createdAt!).inDays <= 30;
            break;
        }
      }

      return matchesSearch && matchesFilter && matchesTime;
    }).toList();

    // Sort the results
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        break;
      case 'date_desc':
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'earnings_desc':
        // Mock sorting by earnings (in real app, you'd have earnings data)
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return filtered;
  }

  double get _totalEarnings {
    // Mock calculation - in real app, this would be actual earnings data
    return _filteredDeliveries.length * 15.50; // $15.50 per delivery average
  }

  int get _completedCount {
    return _filteredDeliveries.where((d) => d.status == 'completed').length;
  }

  double get _averageRating {
    // Mock rating - in real app, this would be actual rating data
    return 4.7;
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
                  label: Text(delivery.statusDisplayName),
                  backgroundColor: delivery.statusColor,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            _buildInfoSection('Delivery Details'),
            _buildInfoRow('Pickup:', delivery.pickupAddress),
            _buildInfoRow('Dropoff:', delivery.dropoffAddress),
            _buildInfoRow('Recipient:', delivery.recipientName ?? 'N/A'),
            _buildInfoRow('Phone:', delivery.recipientPhone ?? 'N/A'),
            _buildInfoRow('Date:', _formatDate(delivery.createdAt)),
            
            if (delivery.status == 'completed') ...[
              const SizedBox(height: 16),
              _buildInfoSection('Completion Details'),
              _buildInfoRow('Delivered At:', _formatDate(delivery.createdAt?.add(Duration(hours: 2)))),
              _buildInfoRow('Delivery Time:', '45 minutes'),
              _buildInfoRow('Distance:', '${delivery.distance.toStringAsFixed(1)} km'),
              _buildInfoRow('Earnings:', '\$15.50'),
              _buildInfoRow('Customer Rating:', '⭐ 4.8'),
              _buildInfoRow('Notes:', delivery.instructions ?? 'No additional notes'),
            ],
            
            if (delivery.status == 'cancelled') ...[
              const SizedBox(height: 16),
              _buildInfoSection('Cancellation Details'),
              _buildInfoRow('Cancelled At:', _formatDate(delivery.createdAt)),
              _buildInfoRow('Reason:', 'Customer requested cancellation'),
              _buildInfoRow('Compensation:', '\$3.00 (cancellation fee)'),
            ],
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Download delivery receipt
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download Receipt'),
                  ),
                ),
                const SizedBox(width: 8),
                if (delivery.status == 'completed')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Report an issue
                      },
                      icon: const Icon(Icons.report_problem),
                      label: const Text('Report Issue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeliveries = _filteredDeliveries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Delivery History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
              const PopupMenuItem(
                value: 'earnings_desc',
                child: Text('Highest Earnings'),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Earnings Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Earnings Summary',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEarningsCard('Total Earned', '\$${_totalEarnings.toStringAsFixed(2)}', Icons.monetization_on),
                      _buildEarningsCard('Deliveries', '$_completedCount', Icons.local_shipping),
                      _buildEarningsCard('Avg Rating', _averageRating.toStringAsFixed(1), Icons.star),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
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
                      value: _timeFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Time')),
                        DropdownMenuItem(value: 'today', child: Text('Today')),
                        DropdownMenuItem(value: 'week', child: Text('This Week')),
                        DropdownMenuItem(value: 'month', child: Text('This Month')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _timeFilter = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Delivery History List
          Expanded(
            child: filteredDeliveries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No delivery history found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete some deliveries to see your history here',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = filteredDeliveries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: delivery.statusColor,
                            child: Icon(
                              delivery.status == 'completed' 
                                  ? Icons.check_circle 
                                  : Icons.cancel,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text('Delivery #${delivery.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To: ${delivery.recipientName ?? "Unknown"}'),
                              Text('${delivery.dropoffAddress}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(delivery.createdAt),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  const Spacer(),
                                  if (delivery.status == 'completed') ...[
                                    Icon(Icons.monetization_on, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '\$15.50',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                delivery.statusDisplayName,
                                style: TextStyle(
                                  color: delivery.statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (delivery.status == 'completed')
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    Text('4.8', style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                            ],
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

  Widget _buildEarningsCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}