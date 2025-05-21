import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/delivery.dart';
import '../services/mock_delivery_service.dart';

class CourierDashboard extends StatefulWidget {
  const CourierDashboard({super.key});

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  final MockDeliveryService _deliveryService = MockDeliveryService();
  List<Delivery> _allDeliveries = [];
  List<Delivery> _availableDeliveries = [];
  List<Delivery> _myDeliveries = [];
  bool _showMapView = false;
  String _courierStatus = 'available';
  GoogleMapController? _mapController;
  final LatLng _courierLocation = const LatLng(37.4219999, -122.0840575); // Mock location
  double _operationalRadius = 5.0; // in kilometers
  Set<Circle> _circles = {};
  Delivery? _recommendedDelivery;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _updateOperationalAreaCircle();
  }

  void _loadDeliveries() {
    _allDeliveries = _deliveryService.getMockDeliveries();
    _filterDeliveriesByRadius();
    _findRecommendedDelivery();
  }

  void _filterDeliveriesByRadius() {
    setState(() {
      _availableDeliveries = _allDeliveries.where((delivery) {
        double distance = _calculateDistance(
          _courierLocation.latitude,
          _courierLocation.longitude,
          delivery.pickupLocation.latitude,
          delivery.pickupLocation.longitude,
        );
        return distance <= _operationalRadius;
      }).toList();
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula to calculate distance between two points on earth
    var p = 0.017453292519943295; // Math.PI / 180
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  void _updateOperationalAreaCircle() {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('operationalArea'),
          center: _courierLocation,
          radius: _operationalRadius * 1000, // convert to meters
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _findRecommendedDelivery() {
    if (_availableDeliveries.isEmpty) {
      setState(() {
        _recommendedDelivery = null;
      });
      return;
    }

    // Find the delivery with the shortest distance from courier
    Delivery optimal = _availableDeliveries.reduce((curr, next) {
      double currDistance = _calculateDistance(
        _courierLocation.latitude,
        _courierLocation.longitude,
        curr.pickupLocation.latitude,
        curr.pickupLocation.longitude,
      );
      
      double nextDistance = _calculateDistance(
        _courierLocation.latitude,
        _courierLocation.longitude,
        next.pickupLocation.latitude,
        next.pickupLocation.longitude,
      );
      
      return currDistance < nextDistance ? curr : next;
    });
    
    setState(() {
      _recommendedDelivery = optimal;
    });
  }

  void _showDeliveryDetails(Delivery delivery) {
    bool isRecommended = _recommendedDelivery?.id == delivery.id;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Delivery Details', style: Theme.of(context).textTheme.headlineSmall),
                if (isRecommended) const SizedBox(width: 8),
                if (isRecommended)
                  Tooltip(
                    message: 'Recommended delivery based on your location',
                    child: Icon(Icons.stars, color: Colors.amber),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Pickup: ${delivery.pickupAddress}'),
            Text('Dropoff: ${delivery.dropoffAddress}'),
            Text('Description: ${delivery.description}'),
            const SizedBox(height: 8),
            Text(
              'Distance from you: ${_calculateDistance(
                _courierLocation.latitude,
                _courierLocation.longitude,
                delivery.pickupLocation.latitude,
                delivery.pickupLocation.longitude,
              ).toStringAsFixed(2)} km',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement accept delivery
                    setState(() {
                      _myDeliveries.add(delivery);
                      _availableDeliveries.remove(delivery);
                      if (_recommendedDelivery?.id == delivery.id) {
                        _findRecommendedDelivery();
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: isRecommended 
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      )
                    : null,
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
            child: Column(
              children: [
                Row(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showMapView ? Colors.blue : Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showMapView = true;
                        });
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Map View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showMapView ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Operational Radius: ${_operationalRadius.toStringAsFixed(1)} km',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_availableDeliveries.length} deliveries in range',
                            style: TextStyle(
                              color: _availableDeliveries.isEmpty 
                                  ? Colors.red 
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _operationalRadius,
                        min: 1.0,
                        max: 20.0,
                        divisions: 19,
                        label: _operationalRadius.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _operationalRadius = value;
                            _updateOperationalAreaCircle();
                            _filterDeliveriesByRadius();
                            _findRecommendedDelivery();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_recommendedDelivery != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recommended: Delivery #${_recommendedDelivery!.id} - ${_calculateDistance(
                              _courierLocation.latitude,
                              _courierLocation.longitude,
                              _recommendedDelivery!.pickupLocation.latitude,
                              _recommendedDelivery!.pickupLocation.longitude,
                            ).toStringAsFixed(2)} km away',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showDeliveryDetails(_recommendedDelivery!),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
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
                    circles: _circles,
                    markers: {
                      Marker(
                        markerId: const MarkerId('courier'),
                        position: _courierLocation,
                        infoWindow: const InfoWindow(title: 'Your Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                      ),
                      ..._availableDeliveries.map(
                        (delivery) => Marker(
                          markerId: MarkerId(delivery.id),
                          position: delivery.pickupLocation,
                          infoWindow: InfoWindow(
                            title: 'Pickup: ${delivery.pickupAddress}',
                            snippet: 'Tap for details',
                          ),
                          icon: _recommendedDelivery?.id == delivery.id
                              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow)
                              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          onTap: () => _showDeliveryDetails(delivery),
                        ),
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  )
                : _availableDeliveries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No deliveries within your operational radius',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _operationalRadius += 5.0;
                                  if (_operationalRadius > 20) _operationalRadius = 20;
                                  _updateOperationalAreaCircle();
                                  _filterDeliveriesByRadius();
                                  _findRecommendedDelivery();
                                });
                              },
                              child: const Text('Increase Radius'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _availableDeliveries.length,
                        itemBuilder: (context, index) {
                          final delivery = _availableDeliveries[index];
                          final isRecommended = _recommendedDelivery?.id == delivery.id;
                          
                          return Card(
                            margin: const EdgeInsets.all(8),
                            elevation: isRecommended ? 4 : 1,
                            color: isRecommended ? Colors.amber.withOpacity(0.1) : null,
                            shape: isRecommended 
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.amber, width: 1),
                                  )
                                : null,
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text('Delivery #${delivery.id}'),
                                  if (isRecommended) const SizedBox(width: 8),
                                  if (isRecommended)
                                    const Icon(Icons.stars, color: Colors.amber, size: 20),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('From: ${delivery.pickupAddress}'),
                                  Text('To: ${delivery.dropoffAddress}'),
                                  Text(
                                    'Distance: ${_calculateDistance(
                                      _courierLocation.latitude,
                                      _courierLocation.longitude,
                                      delivery.pickupLocation.latitude,
                                      delivery.pickupLocation.longitude,
                                    ).toStringAsFixed(2)} km',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info),
                                onPressed: () => _showDeliveryDetails(delivery),
                              ),
                              onTap: () => _showDeliveryDetails(delivery),
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