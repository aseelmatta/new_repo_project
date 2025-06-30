import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/delivery.dart';
import '../services/delivery_service.dart';

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
  Timer? _locationUpdateTimer;
  
  // Courier location tracking
  LatLng _courierLocation = const LatLng(37.4219983, -122.084);
  LatLng _targetLocation  = const LatLng(37.4219983, -122.084);

  // Service & subscription
  final _svc               = DeliveryService();
  StreamSubscription<Position>? _posSub;
  
  // Delivery status tracking
  String _currentStatus      = 'accepted';
  bool   _isMoving           = false;
  double _estimatedTimeMinutes = 15.0;
  double _distanceToDestination = 2.5; // km
  
  // Animation and tracking
  List<LatLng> _courierPath = [];
  Set<Marker> _markers      = {};
  Set<Polyline> _polylines  = {};
  Set<Circle>   _circles    = {};
  

@override
void initState() {
  super.initState();
  Geolocator.requestPermission().then((_) {
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen(_onPosition);
  });
  _initializeTracking();
  _startLocationUpdates();
}


  @override
  void dispose() {
    _posSub?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeTracking() {
    // Set initial courier location near pickup
    _courierLocation = LatLng(
      widget.delivery.pickupLocation.latitude + 0.002,
      widget.delivery.pickupLocation.longitude + 0.001,
    );
    // Set target based on delivery status
    _updateTargetLocation();
    _updateMapElements();
  }

  void _updateTargetLocation() {
    switch (_currentStatus) {
      case 'accepted':
      case 'heading_to_pickup':
      case 'arrived_at_pickup':
        _targetLocation = widget.delivery.pickupLocation;
        break;
      case 'picked_up':
      case 'in_transit':
      case 'arrived_at_dropoff':
      case 'delivered':
        _targetLocation = widget.delivery.dropoffLocation;
        break;
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isMoving && _currentStatus != 'delivered') {
        _simulateCourierMovement();
        _updateDeliveryProgress();
      }
    });
    // Start moving automatically
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isMoving = true;
        if (_currentStatus == 'accepted') {
          _currentStatus = 'heading_to_pickup';
        }
      });
    });
  }

  Future<void> _onPosition(Position pos) async {
    setState(() {
      _courierLocation = LatLng(pos.latitude, pos.longitude);
      _courierPath.add(_courierLocation);
      _updateMapElements();
      _updateCameraPosition();
    });
    await DeliveryService.updateLocation(pos.latitude, pos.longitude);
  }

  void _simulateCourierMovement() {
    double distance = _calculateDistance(_courierLocation, _targetLocation);
    if (distance < 0.0001) {
      _handleArrival();
      return;
    }
    double moveDistance = 0.0002;
    double bearing      = _calculateBearing(_courierLocation, _targetLocation);
    LatLng newLocation  = _moveTowards(_courierLocation, bearing, moveDistance);

    setState(() {
      _courierLocation       = newLocation;
      _courierPath.add(newLocation);
      _distanceToDestination = distance * 111; 
      _estimatedTimeMinutes  = (_distanceToDestination / 0.5) * 60;
      if (_estimatedTimeMinutes < 1) _estimatedTimeMinutes = 1;
    });
    _updateMapElements();
    _updateCameraPosition();
  }

  void _handleArrival() {
    setState(() => _isMoving = false);
    switch (_currentStatus) {
      case 'heading_to_pickup':
        _updateStatus('arrived_at_pickup');
        _showStatusUpdate('Courier has arrived at pickup location!', Icons.location_on);
        Future.delayed(const Duration(seconds: 5), () {
          _updateStatus('picked_up');
          _showStatusUpdate('Package picked up! Heading to delivery location.', Icons.inventory);
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              _isMoving = true;
              _currentStatus = 'in_transit';
            });
          });
        });
        break;
      case 'in_transit':
        _updateStatus('arrived_at_dropoff');
        _showStatusUpdate('Courier has arrived at delivery location!', Icons.local_shipping);
        Future.delayed(const Duration(seconds: 5), () {
          _updateStatus('delivered');
          _showDeliveryComplete();
        });
        break;
    }
  }

  void _updateStatus(String newStatus) {
    setState(() => _currentStatus = newStatus);
    _updateTargetLocation();
    _updateMapElements();
  }

  void _showStatusUpdate(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeliveryComplete() {
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
            Text('Your package has been successfully delivered to:'),
            const SizedBox(height: 8),
            Text(
              widget.delivery.dropoffAddress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate Your Courier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your delivery experience?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setDialogState(() => rating = index + 1);
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for rating $rating stars!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDeliveryProgress() {
    double totalDistance     = _calculateDistance(
      widget.delivery.pickupLocation,
      widget.delivery.dropoffLocation,
    );
    double remainingDistance = _calculateDistance(_courierLocation, _targetLocation);
    setState(() {
      if (_currentStatus == 'in_transit') {
        _estimatedTimeMinutes = (remainingDistance / totalDistance) * 20;
      }
    });
  }

  void _updateMapElements() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    final circles   = <Circle>{};

    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: widget.delivery.pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Pickup Location',
        snippet: widget.delivery.pickupAddress,
      ),
    ));
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: widget.delivery.dropoffLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Delivery Location',
        snippet: widget.delivery.dropoffAddress,
      ),
    ));
    markers.add(Marker(
      markerId: const MarkerId('courier'),
      position: _courierLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        (_currentStatus == 'picked_up' || _currentStatus == 'in_transit')
            ? BitmapDescriptor.hueBlue
            : BitmapDescriptor.hueOrange,
      ),
      infoWindow: InfoWindow(
        title: 'Courier Location',
        snippet: _getStatusText(),
      ),
    ));

    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [widget.delivery.pickupLocation, widget.delivery.dropoffLocation],
      color: Colors.blue.withOpacity(0.5),
      width: 3,
      patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    ));
    if (_courierPath.length > 1) {
      polylines.add(Polyline(
        polylineId: const PolylineId('courier_path'),
        points: _courierPath,
        color: Colors.green,
        width: 4,
      ));
    }

    circles.add(Circle(
      circleId: const CircleId('delivery_area'),
      center: _targetLocation,
      radius: 100,
      fillColor: Colors.blue.withOpacity(0.1),
      strokeColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
    ));

    setState(() {
      _markers   = markers;
      _polylines = polylines;
      _circles   = circles;
    });
  }

  void _updateCameraPosition() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_courierLocation),
    );
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case 'accepted':          return 'Courier assigned';
      case 'heading_to_pickup': return 'Heading to pickup';
      case 'arrived_at_pickup': return 'Arrived at pickup';
      case 'picked_up':         return 'Package picked up';
      case 'in_transit':        return 'Delivering package';
      case 'arrived_at_dropoff':return 'Arrived at delivery location';
      case 'delivered':         return 'Package delivered';
      default:                  return 'In progress';
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'delivered':         return Colors.green;
      case 'in_transit':
      case 'picked_up':         return Colors.blue;
      case 'arrived_at_pickup':
      case 'arrived_at_dropoff':return Colors.orange;
      default:                  return Colors.grey;
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p)/2 +
            c(p1.latitude * p) * c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude  * math.pi / 180;
    double lng1 = start.longitude * math.pi / 180;
    double lat2 = end.latitude    * math.pi / 180;
    double lng2 = end.longitude   * math.pi / 180;
    double dLng = lng2 - lng1;
    double y = math.sin(dLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
               math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return math.atan2(y, x);
  }

  LatLng _moveTowards(LatLng start, double bearing, double distance) {
    double lat1 = start.latitude  * math.pi / 180;
    double lng1 = start.longitude * math.pi / 180;
    double lat2 = math.asin(math.sin(lat1) * math.cos(distance) +
                math.cos(lat1) * math.sin(distance) * math.cos(bearing));
    double lng2 = lng1 + math.atan2(
                math.sin(bearing) * math.sin(distance) * math.cos(lat1),
                math.cos(distance) - math.sin(lat1) * math.sin(lat2));
    return LatLng(lat2 * 180/math.pi, lng2 * 180/math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${widget.delivery.id}'),
        backgroundColor: _getStatusColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _updateMapElements();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location updated'),
                               duration: Duration(seconds: 1)),
              );
            },
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isMoving ? Icons.directions_car : Icons.location_on,
                    color: Colors.white, size: 20,
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
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                      if (_currentStatus != 'delivered')
                        Text(
                          'ETA: ${_estimatedTimeMinutes.toInt()} minutes',
                          style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_currentStatus != 'delivered')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_distanceToDestination.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'remaining',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600],
                        ),
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
                target: _courierLocation, zoom: 15,
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
          // Courier info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1, blurRadius: 5,
                offset: const Offset(0, -3),
              )],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '4.8 (127 reviews)',
                            style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Honda Civic • ABC-1234',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening chat with courier...')),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.1)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling courier...')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
