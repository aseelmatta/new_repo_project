import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import '../services/auth_service.dart';
import '../services/delivery_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DeliveryTrackingPage extends StatefulWidget {
  final Delivery delivery;
  
  const DeliveryTrackingPage({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  GoogleMapController? _mapController;
  Timer? _statusUpdateTimer;
  
  // Current delivery data
  Delivery _currentDelivery;
  LatLng? _courierLocation;
  
  // UI state
  bool _isLoading = true;
  String? _errorMessage;
  
  // Map elements
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  
  // Real courier info from backend
  Map<String, dynamic>? _courierInfo;

  _DeliveryTrackingPageState() : _currentDelivery = Delivery(
    id: '',
    pickupLocation: const LatLng(0, 0),
    pickupAddress: '',
    dropoffLocation: const LatLng(0, 0),
    dropoffAddress: '',
    status: 'pending',
    description: '',
  );

  @override
  void initState() {
    super.initState();
    _currentDelivery = widget.delivery;
    _loadDeliveryDetails();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch latest delivery details from backend
      final response = await DeliveryService.getDelivery(_currentDelivery.id);
      
      if (response.success && response.data != null) {
        setState(() {
          _currentDelivery = response.data!;
          _isLoading = false;
        });
        
        // Load courier info and location if delivery is assigned
        if (_currentDelivery.assignedCourier != null) {
          await _loadCourierInfo();
          await _loadCourierLocation();
        }
        
        _updateMapElements();
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load delivery details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading delivery: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourierInfo() async {
    if (_currentDelivery.assignedCourier == null) return;
    
    try {
      // Fetch courier profile from backend using getUserProfile with courier's UID
      // Note: In a real app, you'd have a specific endpoint to get courier info by ID
      // For now, we'll use a placeholder since your backend doesn't have this endpoint yet
      
      setState(() {
        _courierInfo = {
          'uid': _currentDelivery.assignedCourier,
          'name': 'Assigned Courier', // Would come from courier's profile
          'rating': 0.0, // Would come from courier's average rating
          'reviews': 0, // Would come from courier's review count
          'vehicle': 'Vehicle', // Would come from courier's vehicle info
          'plate': 'N/A', // Would come from courier's license plate
          'phone': 'Contact via app', // Would come from courier's phone
        };
      });
      
      // TODO: Implement proper courier info fetching when backend endpoint exists
      // final courierResponse = await CourierService.getCourierInfo(_currentDelivery.assignedCourier!);
      // if (courierResponse.success) {
      //   setState(() {
      //     _courierInfo = courierResponse.data;
      //   });
      // }
      
    } catch (e) {
      print('Error loading courier info: $e');
    }
  }

  Future<void> _loadCourierLocation() async {
    if (_currentDelivery.assignedCourier == null) return;
    
    try {
      // TODO: Implement proper courier location fetching when backend endpoint exists
      // For now, simulate location based on delivery status
      // In production, you'd call something like:
      // final locationResponse = await CourierService.getCourierLocation(_currentDelivery.assignedCourier!);
      
      LatLng baseLocation;
      double randomOffset = 0.001;
      
      switch (_currentDelivery.status) {
        case 'accepted':
        case 'heading_to_pickup':
          baseLocation = LatLng(
            _currentDelivery.pickupLocation.latitude - 0.005 + (math.Random().nextDouble() * 0.01),
            _currentDelivery.pickupLocation.longitude - 0.005 + (math.Random().nextDouble() * 0.01),
          );
          break;
        case 'arrived_at_pickup':
        case 'picked_up':
          baseLocation = LatLng(
            _currentDelivery.pickupLocation.latitude + (math.Random().nextDouble() * randomOffset - randomOffset/2),
            _currentDelivery.pickupLocation.longitude + (math.Random().nextDouble() * randomOffset - randomOffset/2),
          );
          break;
        case 'in_progress':
        case 'in_transit':
          double progress = 0.3 + (math.Random().nextDouble() * 0.4);
          baseLocation = LatLng(
            _currentDelivery.pickupLocation.latitude + 
              ((_currentDelivery.dropoffLocation.latitude - _currentDelivery.pickupLocation.latitude) * progress),
            _currentDelivery.pickupLocation.longitude + 
              ((_currentDelivery.dropoffLocation.longitude - _currentDelivery.pickupLocation.longitude) * progress),
          );
          break;
        case 'arrived_at_dropoff':
        case 'delivered':
          baseLocation = LatLng(
            _currentDelivery.dropoffLocation.latitude + (math.Random().nextDouble() * randomOffset - randomOffset/2),
            _currentDelivery.dropoffLocation.longitude + (math.Random().nextDouble() * randomOffset - randomOffset/2),
          );
          break;
        default:
          baseLocation = _currentDelivery.pickupLocation;
      }
      
      setState(() {
        _courierLocation = baseLocation;
      });
      
    } catch (e) {
      print('Error loading courier location: $e');
    }
  }

  void _startPeriodicUpdates() {
    // Poll for updates every 10 seconds
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _currentDelivery.status != 'completed' && _currentDelivery.status != 'cancelled') {
        _loadDeliveryDetails();
      }
    });
  }


/// Cancel button handler
Future<void> _cancelDelivery() async {
  // 1) Ask user to confirm
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Cancel Delivery?'),
      content: const Text('Are you sure you want to cancel this delivery?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  if (confirm != true) return;

  // 2) Grab the business/user ID from FirebaseAuth
  final businessId = FirebaseAuth.instance.currentUser?.uid;
  if (businessId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must be logged in to cancel.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // 3) Call the service with both required args
  try {
    await DeliveryService.cancelDelivery(
      _currentDelivery.id,  // delivery ID
      businessId,           // who’s cancelling
    );

    // 4) Update UI on success
    setState(() {
      _currentDelivery = _currentDelivery.copyWith(status: 'cancelled');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery cancelled'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    // 5) Show error if it fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cancel failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ——————————————————————————————————————————————————————————————————————————

  void _updateMapElements() {
    Set<Marker> markers = {};
    Set<Polyline> polylines = {};
    Set<Circle> circles = {};
    
    // Pickup marker
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: _currentDelivery.pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Pickup Location',
        snippet: _currentDelivery.pickupAddress,
      ),
    ));
    
    // Dropoff marker
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: _currentDelivery.dropoffLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Delivery Location',
        snippet: _currentDelivery.dropoffAddress,
      ),
    ));
    
    // Courier marker (if location available)
    if (_courierLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('courier'),
        position: _courierLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getStatusColor() == Colors.green ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueOrange
        ),
        infoWindow: InfoWindow(
          title: '${_courierInfo?['name'] ?? 'Courier'}',
          snippet: _getStatusText(),
        ),
      ));
      
      circles.add(Circle(
        circleId: const CircleId('courier_radius'),
        center: _courierLocation!,
        radius: 100,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      ));
    }
    
    // Route from pickup to dropoff
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [_currentDelivery.pickupLocation, _currentDelivery.dropoffLocation],
      color: Colors.blue.withOpacity(0.5),
      width: 3,
      patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    ));
    
    setState(() {
      _markers = markers;
      _polylines = polylines;
      _circles = circles;
    });
  }

  String _getStatusText() {
    switch (_currentDelivery.status) {
      case 'pending':
        return 'Looking for courier...';
      case 'accepted':
        return 'Courier assigned';
      case 'heading_to_pickup':
        return 'Heading to pickup';
      case 'arrived_at_pickup':
        return 'Arrived at pickup';
      case 'picked_up':
        return 'Package picked up';
      case 'in_progress':
      case 'in_transit':
        return 'Delivering package';
      case 'arrived_at_dropoff':
        return 'Arrived at delivery location';
      case 'completed':
        return 'Package delivered';
      case 'cancelled':
        return 'Delivery cancelled';
      default:
        return 'Status: ${_currentDelivery.status}';
    }
  }

  Color _getStatusColor() {
    return _currentDelivery.statusColor;
  }

  double? _getDistanceToDestination() {
    if (_courierLocation == null) return null;
    
    LatLng destination;
    switch (_currentDelivery.status) {
      case 'accepted':
      case 'heading_to_pickup':
        destination = _currentDelivery.pickupLocation;
        break;
      case 'picked_up':
      case 'in_progress':
      case 'in_transit':
        destination = _currentDelivery.dropoffLocation;
        break;
      default:
        return null;
    }
    
    return _calculateDistance(_courierLocation!, destination);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) * c(point2.latitude * p) *
        (1 - c((point2.longitude - point1.longitude) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  int _getEstimatedTime() {
    double? distance = _getDistanceToDestination();
    if (distance == null) return 0;
    
    double timeInHours = distance / 30; // 30 km/h average
    return (timeInHours * 60).round();
  }

  void _showContactOptions() {
    if (_courierInfo == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${_courierInfo!['name'] ?? 'Courier'}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Courier'),
              subtitle: Text(_courierInfo!['phone'] ?? 'Contact via app'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement actual phone call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling courier...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Send Message'),
              subtitle: const Text('Chat with your courier'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement in-app messaging
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening chat...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryComplete() {
    if (_currentDelivery.status != 'completed') return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Delivery Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your package has been successfully delivered to:'),
            const SizedBox(height: 8),
            Text(
              _currentDelivery.dropoffAddress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Recipient: ${_currentDelivery.recipientName ?? 'N/A'}'),
            const SizedBox(height: 16),
            const Text('Would you like to rate your courier?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRatingDialog();
            },
            child: const Text('Rate Courier'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    if (_courierInfo == null) return;
    
    int rating = 5;
    TextEditingController feedbackController = TextEditingController();
    bool isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rate ${_courierInfo!['name'] ?? 'Your Courier'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your delivery experience with ${_courierInfo!['name'] ?? 'your courier'}?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: isSubmitting ? null : () {
                      setDialogState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text('$rating star${rating != 1 ? 's' : ''}'),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                enabled: !isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Feedback (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Share your experience...',
                ),
                maxLines: 3,
              ),
              if (isSubmitting) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setDialogState(() {
                  isSubmitting = true;
                });
                
                await _submitRating(rating, feedbackController.text);
                
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to dashboard
              },
              child: isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(int rating, String feedback) async {
    try {
      // TODO: Create a rating endpoint in your backend
      // For now, we'll use the delivery update endpoint to store the rating
      // In production, you'd call something like:
      // await RatingService.submitRating(_currentDelivery.id, _currentDelivery.assignedCourier!, rating, feedback);
      
      // For now, just show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for rating $rating stars!'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('Rating submitted: $rating stars for delivery ${_currentDelivery.id}');
      print('Feedback: $feedback');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Delivery #${_currentDelivery.id}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Delivery #${_currentDelivery.id}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Delivery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDeliveryDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${_currentDelivery.id}'),
        backgroundColor: _getStatusColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveryDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getStatusColor().withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _currentDelivery.status == 'completed' 
                            ? Icons.check_circle 
                            : _currentDelivery.status == 'cancelled'
                                ? Icons.cancel
                                : Icons.local_shipping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                          if (_getEstimatedTime() > 0)
                            Text(
                              'ETA: ${_getEstimatedTime()} minutes',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_getDistanceToDestination() != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_getDistanceToDestination()!.toStringAsFixed(1)} km',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'remaining',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _courierLocation ?? _currentDelivery.pickupLocation,
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              circles: _circles,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          
          // Courier info card (only show if delivery is assigned and not completed)
          if (_currentDelivery.assignedCourier != null && 
              _currentDelivery.status != 'completed' && 
              _currentDelivery.status != 'cancelled' &&
              _courierInfo != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue,
                    child: Text(
                      (_courierInfo!['name'] ?? 'C')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _courierInfo!['name'] ?? 'Courier',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_courierInfo!['rating'] != null && _courierInfo!['rating'] > 0)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_courierInfo!['rating']} (${_courierInfo!['reviews']} reviews)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        if (_courierInfo!['vehicle'] != null)
                          Text(
                            '${_courierInfo!['vehicle']} • ${_courierInfo!['plate'] ?? 'N/A'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showContactOptions,
                    icon: const Icon(Icons.contact_phone, size: 18),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


