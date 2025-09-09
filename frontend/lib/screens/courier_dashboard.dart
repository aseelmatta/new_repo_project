import 'dart:core';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import 'courier_history_page.dart';
import 'courier_profile_page.dart';

import 'dart:async';                  // for StreamSubscription
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// Extension method to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}



class CourierDashboard extends StatefulWidget {
  const CourierDashboard({super.key});

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  DateTime _lastSentToServer = DateTime.fromMillisecondsSinceEpoch(0);
  
  
  List<Delivery> _allDeliveries = [];
  List<Delivery> _availableDeliveries = [];
  List<Delivery> _myDeliveries = [];
  bool _showMapView = false;
  String _courierStatus = 'available';
  GoogleMapController? _mapController;
  LatLng _courierLocation = const LatLng(37.4219999, -122.0840575);
  StreamSubscription<Position>? _positionSub;

  double _operationalRadius = 5.0; // in kilometers
  Set<Circle> _circles = {};
  Delivery? _recommendedDelivery;
  int _currentIndex = 0; // For bottom navigation
  PageController? _pageController;

  // Subscription to listen for real‑time updates over WebSockets
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDeliveries();
    _updateOperationalAreaCircle();
    _startLocationUpdates();

    // Subscribe to WebSocket events for new assignments and status updates.
    // When a relevant event arrives, refresh the list of deliveries.
    DeliveryService.connectForUpdates().then((stream) {
      _wsSub = stream.listen((event) {
        print('WS EVENT: $event'); // 🔍 added log
        final type = event['event'];
        if (type == 'delivery_assigned' ||
            type == 'new_delivery' ||
            type == 'delivery_status_update') {
          _loadDeliveries();
        }
      });
    });

  }

  @override
  void dispose() {
    // Cancel the WebSocket subscription when the dashboard is destroyed
    _wsSub?.cancel();
    _positionSub?.cancel();
    _pageController?.dispose();
    super.dispose();
  }
  // HELPER METHOD FOR CONSISTENT DETAIL ROWS
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontSize: 14,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3, // Allow up to 3 lines for longer addresses
          ),
        ),
      ],
    ),
  );
 }
  Future<void> _startLocationUpdates() async {
    // 1. Request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        // handle appropriately (show dialog, disable map, etc.)
        return;
      }
    }

    // 2. Subscribe to position updates
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,      // only fire when moved ≥50m
      ),
    ).listen(_onPositionUpdate, onError: (err) => print("Loc error: $err"));

  }

  void _onPositionUpdate(Position pos) {
  final newLoc = LatLng(pos.latitude, pos.longitude);

    // Always update the UI immediately:
    setState(() {
      _courierLocation = newLoc;
      _updateOperationalAreaCircle();
      _filterDeliveriesByRadius();
      _findRecommendedDelivery();
    });

    // But only call the backend at most once every 10s:
    final now = DateTime.now();
    if (now.difference(_lastSentToServer) < Duration(seconds: 10)) return;
    _lastSentToServer = now;

    DeliveryService.updateLocation(pos.latitude, pos.longitude)
      .then((resp) {
        if (!resp.success) print("Failed to update location: ${resp.error}");
      });
    // NOTE: Previously we reloaded deliveries on every location update to
    // discover new assignments.  With WebSocket notifications, this polling
    // is no longer needed.  The call below is kept for reference but is
    // commented out.  When an assignment occurs the server will emit a
    // WebSocket event that triggers a refresh in the initState subscription.
    /*
    DeliveryService.getDeliveries().then((resp) {
      if (resp.success) {
        setState(() {
          _allDeliveries = resp.data!;
        });
      }
    });
    */
        // — PICKUP DETECTION —
  for (var delivery in _allDeliveries) {
    if (delivery.status == 'accepted') {
      final pickupDist = _calculateDistance(
        pos.latitude, pos.longitude,
        delivery.pickupLocation.latitude, delivery.pickupLocation.longitude,
      );
      if (pickupDist < 0.2) {
        DeliveryService.updateDeliveryStatus(delivery.id, 'in_progress')
          .then((resp) {
            if (resp.success) {
              setState(() => delivery.status = 'in_progress');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Picked up delivery #${delivery.id}!',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              //navigate to pickup location
              _showNavigationPrompt(delivery, 'pickup');
            }
          });
        break;
      }
    }
  }

  // — DROP-OFF DETECTION —
  for (var delivery in _allDeliveries) {
    if (delivery.status == 'in_progress') {
      final dropDist = _calculateDistance(
        pos.latitude, pos.longitude,
        delivery.dropoffLocation.latitude, delivery.dropoffLocation.longitude,
      );
      if (dropDist < 0.2) {
        DeliveryService.updateDeliveryStatus(delivery.id, 'completed')
          .then((resp) {
            if (resp.success) {
              setState(() {
                delivery.status = 'completed';
                _allDeliveries.removeWhere((d) => d.id == delivery.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completed delivery #${delivery.id}!',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              //navigate to dropoff location
              _showNavigationPrompt(delivery, 'dropoff');
            }
          });
        break;
      }
    }
  }
      
  }
  void _showNavigationPrompt(Delivery delivery, String type) {
  // Wait a moment to show the popup after the pickup/dropoff notification
  Future.delayed(const Duration(seconds: 1), () {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Navigate to ${type.capitalize()} Location'),
          content: Text(
            type == 'dropoff'
                ? 'You\'ve picked up the delivery. Would you like to navigate to the dropoff location?'
                : 'Would you like to navigate to the pickup location?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLocation(
                  type == 'dropoff' ? delivery.dropoffLocation : delivery.pickupLocation,
                  type,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Navigate Now'),
            ),
          ],
        );
      },
    );
  });
 }



  Future<void> _loadDeliveries() async {
    // 1. Fetch all deliveries from the backend
    final resp = await DeliveryService.getDeliveries();

    // 2. If there was an error, show it and stop
    if (!resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading deliveries: ${resp.error}')),
      );
      return;
    }

    // 3. Update the full list in state
    setState(() {
      _allDeliveries = resp.data!;
    });

    // 4. Filter by your operational radius and pick a recommendation
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
        return distance <= _operationalRadius && delivery.status == 'pending'|| delivery.status == 'accepted'||
         delivery.status == 'in_progress';
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
 void _navigateToLocation(LatLng location, String type) async {
  final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=driving&dir_action=navigate';
  
  try {
    if (await canLaunch(url)) {
      await launch(url);
      
      // Show a snackbar to confirm navigation has started
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.navigation, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Navigating to ${type == 'pickup' ? 'pickup' : 'dropoff'} location',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Handle case where Google Maps cannot be launched
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch Google Maps. Make sure it is installed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error launching navigation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error launching navigation: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
 }
 void _showDeliveryDetails(Delivery delivery) {
  bool isRecommended = _recommendedDelivery?.id == delivery.id;
  
  // Compute mid-point & markers for map
  LatLng pickup = delivery.pickupLocation;
  LatLng dropoff = delivery.dropoffLocation;
  LatLng center = LatLng(
    (pickup.latitude + dropoff.latitude) / 2,
    (pickup.longitude + dropoff.longitude) / 2,
  );

  Set<Marker> markers = {
    Marker(
      markerId: const MarkerId('pickup'),
      position: pickup,
      infoWindow: const InfoWindow(title: 'Pickup'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('dropoff'),
      position: dropoff,
      infoWindow: const InfoWindow(title: 'Drop-off'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
  };

  List<LatLng> route = [pickup, dropoff];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: false, // Prevent accidental dismissal
    builder: (BuildContext ctx) {
      return FractionallySizedBox(
        heightFactor: 0.75, // Fixed at 75% height
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: <Widget>[
              // Handle + close button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Header with ID and status
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Delivery #${delivery.id}',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isRecommended) const SizedBox(width: 8),
                    if (isRecommended)
                      Tooltip(
                        message: 'Recommended delivery based on your location',
                        child: Icon(Icons.stars, color: Colors.amber),
                      ),
                  ],
                ),
              ),

              // The map
              Expanded(
                flex: 2,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: center, zoom: 13),
                  markers: markers,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: route,
                      color: Colors.blue,
                      width: 4,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),

              // The textual details
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildDetailRow('Pickup:', delivery.pickupAddress),
                      _buildDetailRow('Dropoff:', delivery.dropoffAddress),
                      _buildDetailRow('Description:', delivery.description),
                      
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Distance:',
                        '${_calculateDistance(
                          _courierLocation.latitude,
                          _courierLocation.longitude,
                          delivery.pickupLocation.latitude,
                          delivery.pickupLocation.longitude,
                        ).toStringAsFixed(2)} km from you',
                      ),
                      
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Estimated earnings:',
                        '\$${delivery.fee?.toStringAsFixed(2) ?? (15.0 + math.Random().nextDouble() * 10).toStringAsFixed(2)}',
                        valueColor: Colors.green,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Navigation buttons based on status
                      if (delivery.status == 'pending' || delivery.status == 'accepted')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToLocation(
                              delivery.status == 'pending' || delivery.status == 'accepted' 
                                  ? delivery.pickupLocation
                                  : delivery.dropoffLocation,
                              delivery.status == 'pending' || delivery.status == 'accepted'
                                  ? 'pickup'
                                  : 'dropoff',
                            ),
                            icon: const Icon(Icons.navigation),
                            label: Text(
                              delivery.status == 'pending' || delivery.status == 'accepted'
                                  ? 'Navigate to Pickup'
                                  : 'Navigate to Dropoff',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      
                      if (delivery.status == 'in_progress')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToLocation(
                              delivery.dropoffLocation,
                              'dropoff',
                            ),
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate to Dropoff'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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

  Widget _buildDeliveriesPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Status indicator
 // Status indicator with responsive layout
 Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: _courierStatus == 'available' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: _courierStatus == 'available' ? Colors.green : Colors.red,
    ),
  ),
  child: LayoutBuilder(
    builder: (context, constraints) {
      // Check if we need a more compact layout
      final isNarrow = constraints.maxWidth < 300;
      
      if (isNarrow) {
        // Vertical layout for very narrow screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: _courierStatus == 'available' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _courierStatus == 'available' ? 'You are online' : 'You are offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _courierStatus == 'available' ? Colors.green[700] : Colors.red[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _courierStatus = _courierStatus == 'available' ? 'offline' : 'available';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _courierStatus == 'available' ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                child: Text(
                  _courierStatus == 'available' ? 'Go Offline' : 'Go Online',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      } else {
        // Original horizontal layout
        return Row(
          children: [
            CircleAvatar(
              radius: 8,
              backgroundColor: _courierStatus == 'available' ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _courierStatus == 'available' ? 'You are online and available for deliveries' : 'You are offline',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _courierStatus == 'available' ? Colors.green[700] : Colors.red[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _courierStatus = _courierStatus == 'available' ? 'offline' : 'available';
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(_courierStatus == 'available' ? 'Go Offline' : 'Go Online'),
            ),
          ],
        );
      }
    },
  ),
 ),
              
              const SizedBox(height: 8),
              
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
                      backgroundColor: !_showMapView ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
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
                      backgroundColor: _showMapView ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
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
                  // FIX: Make radius info responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 350) {
                        // Stack vertically on narrow screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Operational Radius: ${_operationalRadius.toStringAsFixed(1)} km',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_availableDeliveries.length} deliveries in range',
                              style: TextStyle(
                                color: _availableDeliveries.isEmpty 
                                    ? Colors.red 
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Normal horizontal layout
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Operational Radius: ${_operationalRadius.toStringAsFixed(1)} km',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        );
                      }
                    },
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
                    // FIX: Use Expanded to prevent text overflow
                    Expanded(
                      child: Text(
                        'Recommended: Delivery #${_recommendedDelivery!.id} - ${_calculateDistance(
                          _courierLocation.latitude,
                          _courierLocation.longitude,
                          _recommendedDelivery!.pickupLocation.latitude,
                          _recommendedDelivery!.pickupLocation.longitude,
                        ).toStringAsFixed(2)} km away',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                        maxLines: 2, // Allow up to 2 lines for wrapping
                      ),
                    ),
                    // FIX: Use Flexible for the button to prevent overflow
                    Flexible(
                      child: TextButton(
                        onPressed: () => _showDeliveryDetails(_recommendedDelivery!),
                        child: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _courierStatus != 'available' 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bedtime, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'You\'re currently offline',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Go online to start receiving delivery requests',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _courierStatus = 'available';
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Go Online', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _showMapView
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
                          // FIX: Truncate long delivery IDs in info windows
                          infoWindow: InfoWindow(
                            title: delivery.id.length > 10 
                                ? 'Delivery #${delivery.id.substring(0, 10)}...'
                                : 'Delivery #${delivery.id}',
                            snippet: delivery.pickupAddress.length > 30
                                ? '${delivery.pickupAddress.substring(0, 30)}...'
                                : delivery.pickupAddress,
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
                            final distance = _calculateDistance(
                              _courierLocation.latitude,
                              _courierLocation.longitude,
                              delivery.pickupLocation.latitude,
                              delivery.pickupLocation.longitude,
                            );
                            final estimatedEarnings = 15.0 + math.Random().nextDouble() * 10;
                            
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
                              child: Column(
                                children: [
                                  ListTile(
                                    // FIX: Wrap title in Row with proper constraints
                                    title: Row(
                                      children: [
                                        // FIX: Use Expanded to prevent delivery ID overflow
                                        Expanded(
                                          child: Text(
                                            'Delivery #${delivery.id}',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isRecommended) const SizedBox(width: 8),
                                        if (isRecommended)
                                          const Icon(Icons.stars, color: Colors.amber, size: 20),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // FIX: Use Expanded or constrained width for addresses
                                        Text(
                                          'From: ${delivery.pickupAddress}',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          'To: ${delivery.dropoffAddress}',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        // FIX: Make stats row responsive
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            if (constraints.maxWidth < 200) {
                                              // Stack vertically on very narrow cards
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${distance.toStringAsFixed(2)} km',
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.monetization_on, size: 14, color: Colors.green),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '\$${estimatedEarnings.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.green,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            } else {
                                              // Normal horizontal layout
                                              return Row(
                                                children: [
                                                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${distance.toStringAsFixed(2)} km',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Icon(Icons.monetization_on, size: 14, color: Colors.green),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '\$${estimatedEarnings.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () => _showDeliveryDetails(delivery),
                                  ),
                                  //navigate to delivery button
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showDeliveryDetails(delivery),
                                          child: const Text('Details'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _navigateToLocation(
                                            delivery.status == 'pending' || delivery.status == 'accepted'
                                                ? delivery.pickupLocation
                                                : delivery.dropoffLocation,
                                            delivery.status == 'pending' || delivery.status == 'accepted'
                                                ? 'pickup'
                                                : 'dropoff',
                                          ),
                                          icon: const Icon(Icons.navigation, size: 16),
                                          label: Text(
                                            delivery.status == 'pending' || delivery.status == 'accepted'
                                                ? 'Navigate to Pickup'
                                                : 'Navigate to Dropoff',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  //build the map view


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Available Deliveries' : 
          _currentIndex == 1 ? 'My History' : 'My Profile'
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: _currentIndex == 0 ? [
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
                value: 'offline',
                child: Text('Offline'),
              ),
            ],
            child: Chip(
              label: Text(_courierStatus.toUpperCase()),
              backgroundColor: _courierStatus == 'available' 
                  ? Colors.green 
                  : _courierStatus == 'busy' 
                      ? Colors.orange 
                      : Colors.red,
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ] : null,
      ),
      body: _pageController != null ? PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildDeliveriesPage(),
          const CourierHistoryPage(),
          const CourierProfilePage(),
        ],
      ) : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
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
      ),
    );
  }
}