import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';
import '../services/mock_delivery_service.dart';
import 'business_chat_page.dart';
import 'business_profile_page.dart';

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  final MockDeliveryService _deliveryService = MockDeliveryService();
  List<Delivery> _deliveries = [];
  String _searchQuery = '';
  bool _showMapView = false;
  String _statusFilter = 'all';
  GoogleMapController? _mapController;
  int _currentIndex = 0; // For bottom navigation

  // Page controller for navigation
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDeliveries();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _loadDeliveries() {
    setState(() {
      _deliveries = _deliveryService.getMockDeliveries();
    });
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
            const SizedBox(height: 8),
            _buildInfoSection('Delivery Details'),
            _buildInfoRow('Pickup:', delivery.pickupAddress),
            _buildInfoRow('Dropoff:', delivery.dropoffAddress),
            _buildInfoRow('Description:', delivery.description),
            _buildInfoRow('Created:', '2 hours ago'),
            const SizedBox(height: 16),
            
            if (delivery.status == 'in_progress' || delivery.status == 'accepted')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Courier Information'),
                  _buildInfoRow('Name:', 'John Doe'),
                  _buildInfoRow('Rating:', '4.8 ★'),
                  _buildInfoRow('Expected delivery:', '15:30'),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement messenger
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Message Courier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _showMapView = true;
                            });
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Track Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
            if (delivery.status == 'completed')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Delivery Summary'),
                  _buildInfoRow('Delivered at:', '15:32, May 20, 2025'),
                  _buildInfoRow('Courier:', 'John Doe'),
                  _buildInfoRow('Signature:', 'Available'),
                  _buildInfoRow('Rating:', 'Not rated yet'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement rating
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Rate this Delivery'),
                    ),
                  ),
                ],
              ),
              
            if (delivery.status == 'pending')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Pending Delivery'),
                  _buildInfoRow('Created at:', '13:15, May 21, 2025'),
                  _buildInfoRow('Status:', 'Waiting for courier assignment'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement edit
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement cancel
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
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
            width: 100,
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

  void _showCreateDeliveryForm() {
    LatLng? pickupLocation;
    LatLng? dropoffLocation;
    String pickupAddress = '';
    String dropoffAddress = '';
    bool selectingPickup = true;
    TextEditingController pickupController = TextEditingController();
    TextEditingController dropoffController = TextEditingController();
    GoogleMapController? mapController;
    
    void showMapSelector(BuildContext context, bool isPickup) {
      selectingPickup = isPickup;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                AppBar(
                  title: Text('Select ${isPickup ? 'Pickup' : 'Dropoff'} Location'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (selectingPickup && pickupLocation != null) {
                          pickupAddress = 'Location at ${pickupLocation!.latitude.toStringAsFixed(4)}, ${pickupLocation!.longitude.toStringAsFixed(4)}';
                          pickupController.text = pickupAddress;
                        } else if (!selectingPickup && dropoffLocation != null) {
                          dropoffAddress = 'Location at ${dropoffLocation!.latitude.toStringAsFixed(4)}, ${dropoffLocation!.longitude.toStringAsFixed(4)}';
                          dropoffController.text = dropoffAddress;
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('CONFIRM', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search functionality would connect to Places API')),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(37.4219999, -122.0840575),
                      zoom: 14,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: {
                      if (selectingPickup && pickupLocation != null)
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: pickupLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      if (!selectingPickup && dropoffLocation != null)
                        Marker(
                          markerId: const MarkerId('dropoff'),
                          position: dropoffLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        ),
                    },
                    onTap: (LatLng location) {
                      setModalState(() {
                        if (selectingPickup) {
                          pickupLocation = location;
                        } else {
                          dropoffLocation = location;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setFormState) => Container(
          padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          height: MediaQuery.of(context).size.height * 0.9,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Delivery', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                
                Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pickupController,
                        decoration: const InputDecoration(
                          hintText: 'Pickup address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on, color: Colors.green),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.green),
                      onPressed: () => showMapSelector(context, true),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text('Dropoff Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dropoffController,
                        decoration: const InputDecoration(
                          hintText: 'Dropoff address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.red),
                      onPressed: () => showMapSelector(context, false),
                    ),
                  ],
                ),
                
                // Map preview if both locations are selected
                if (pickupLocation != null && dropoffLocation != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            (pickupLocation!.latitude + dropoffLocation!.latitude) / 2,
                            (pickupLocation!.longitude + dropoffLocation!.longitude) / 2,
                          ),
                          zoom: 12,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('pickup'),
                            position: pickupLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            infoWindow: const InfoWindow(title: 'Pickup'),
                          ),
                          Marker(
                            markerId: const MarkerId('dropoff'),
                            position: dropoffLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            infoWindow: const InfoWindow(title: 'Dropoff'),
                          ),
                        },
                        polylines: {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: [pickupLocation!, dropoffLocation!],
                            color: Colors.blue,
                            width: 5,
                          ),
                        },
                        liteModeEnabled: true,
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                Text('Package Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Package description (size, weight, contents, etc.)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                Text('Recipient Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Recipient Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Recipient Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 16),
                Text('Delivery Instructions (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Special instructions for the courier',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (pickupLocation == null || dropoffLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select both pickup and dropoff locations'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Create Delivery'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dashboard page content
  Widget _buildDashboardPage() {
    final filteredDeliveries = _deliveries.where((delivery) {
      bool matchesSearch = delivery.pickupAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          delivery.dropoffAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          delivery.status.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = _statusFilter == 'all' || delivery.status == _statusFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();

    int pendingCount = _deliveries.where((d) => d.status == 'pending').length;
    int inProgressCount = _deliveries.where((d) => d.status == 'in_progress' || d.status == 'accepted').length;
    int completedCount = _deliveries.where((d) => d.status == 'completed').length;
    int cancelledCount = _deliveries.where((d) => d.status == 'cancelled').length;

    return Column(
      children: [
        // Analytics Card
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Pending', pendingCount, Colors.orange),
                    _buildStatCard('Active', inProgressCount, Colors.blue),
                    _buildStatCard('Completed', completedCount, Colors.green),
                    _buildStatCard('Cancelled', cancelledCount, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 30,
                    child: Row(
                      children: [
                        if (pendingCount > 0) Expanded(flex: pendingCount, child: Container(color: Colors.orange)),
                        if (inProgressCount > 0) Expanded(flex: inProgressCount, child: Container(color: Colors.blue)),
                        if (completedCount > 0) Expanded(flex: completedCount, child: Container(color: Colors.green)),
                        if (cancelledCount > 0) Expanded(flex: cancelledCount, child: Container(color: Colors.red)),
                        if (pendingCount + inProgressCount + completedCount + cancelledCount == 0)
                          Expanded(child: Container(color: Colors.grey[300], child: const Center(child: Text('No deliveries yet')))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(8.0),
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
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
            ],
          ),
        ),
        
        // Toggle buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _showMapView = false),
                icon: const Icon(Icons.list),
                label: const Text('List View'),
                style: ElevatedButton.styleFrom(backgroundColor: !_showMapView ? Colors.blue : Colors.grey),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showMapView = true),
                icon: const Icon(Icons.map),
                label: const Text('Map View'),
                style: ElevatedButton.styleFrom(backgroundColor: _showMapView ? Colors.blue : Colors.grey),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _showMapView
              ? GoogleMap(
                  initialCameraPosition: const CameraPosition(target: LatLng(37.4219999, -122.0840575), zoom: 12),
                  markers: {
                    ...filteredDeliveries.map((delivery) => Marker(
                      markerId: MarkerId(delivery.id),
                      position: delivery.pickupLocation,
                      infoWindow: InfoWindow(title: 'Delivery #${delivery.id}', snippet: delivery.status),
                      icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(delivery.status)),
                      onTap: () => _showDeliveryDetails(delivery),
                    )),
                  },
                  onMapCreated: (controller) => _mapController = controller,
                )
              : filteredDeliveries.isEmpty
                  ? const Center(child: Text('No deliveries found'))
                  : ListView.builder(
                      itemCount: filteredDeliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = filteredDeliveries[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text('Delivery #${delivery.id}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From: ${delivery.pickupAddress}'),
                                Text('To: ${delivery.dropoffAddress}'),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: _getProgressValue(delivery.status),
                                  backgroundColor: Colors.grey[200],
                                  color: _getStatusColor(delivery.status),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_getStatusIcon(delivery.status), color: _getStatusColor(delivery.status)),
                                Text(delivery.status, style: TextStyle(color: _getStatusColor(delivery.status), fontSize: 12)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'FETCH Dashboard' : _currentIndex == 1 ? 'Support Chat' : 'Profile'),
        actions: _currentIndex == 0 ? [
          IconButton(
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMapView = !_showMapView),
          ),
        ] : null,
      ),
      body: _pageController != null ? PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildDashboardPage(),
          const BusinessChatPage(),
          const BusinessProfilePage(),
        ],
      ) : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: _showCreateDeliveryForm,
        label: const Text('New Delivery'),
        icon: const Icon(Icons.add),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), 
            label: 'Dashboard'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), 
            label: 'Support'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profile'
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending': return 0.2;
      case 'accepted': return 0.4;
      case 'in_progress': return 0.7;
      case 'completed': return 1.0;
      case 'cancelled': return 1.0;
      default: return 0.0;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'in_progress': return Icons.local_shipping;
      case 'accepted': return Icons.thumb_up;
      default: return Icons.pending;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'in_progress': return Colors.blue;
      case 'accepted': return Colors.orange;
      default: return Colors.grey;
    }
  }

  double _getMarkerHue(String status) {
    switch (status) {
      case 'completed': return BitmapDescriptor.hueGreen;
      case 'cancelled': return BitmapDescriptor.hueRed;
      case 'in_progress': return BitmapDescriptor.hueBlue;
      case 'accepted': return BitmapDescriptor.hueOrange;
      default: return BitmapDescriptor.hueViolet;
    }
  }
}