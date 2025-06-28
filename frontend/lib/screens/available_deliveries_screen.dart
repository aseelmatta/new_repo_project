// main screen for available deliveries
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/delivery.dart';
import '../widgets/delivery_card.dart';
import '../widgets/delivery_details_sheet.dart';
import '../services/delivery_service.dart';


class AvailableDeliveriesScreen extends StatefulWidget {
  @override
  _AvailableDeliveriesScreenState createState() => _AvailableDeliveriesScreenState();
}

class _AvailableDeliveriesScreenState extends State<AvailableDeliveriesScreen> {
  bool _showMap = false;
  double _operationalRadius = 5.0; // in kilometers
  LatLng? _courierLocation;
  Set<Marker> _deliveryMarkers = {};
  Set<Circle> _operationalAreaCircle = {};
  List<Delivery> _deliveriesInRange = [];
  
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle denied permissions
        return;
      }
    }
    
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _courierLocation = LatLng(position.latitude, position.longitude);
      
      // Add the operational area circle
      _operationalAreaCircle = {
        Circle(
          circleId: CircleId('operationalArea'),
          center: _courierLocation!,
          radius: _operationalRadius * 1000, // Convert km to meters
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 1,
        )
      };
      
      // After setting location, fetch and filter deliveries
      _fetchDeliveries();
    });
  }
  
  Future<void> _fetchDeliveries() async {
    // This would normally come from your backend/Firestore
    final resp = await DeliveryService.getDeliveries();
    final allDeliveries = resp.success ? List<Delivery>.from(resp.data!) : <Delivery>[];
    
    setState(() {
      _deliveriesInRange = _filterDeliveriesInRange(allDeliveries);
      _createDeliveryMarkers();
    });
  }
  
  List<Delivery> _filterDeliveriesInRange(List<Delivery> allDeliveries) {
    if (_courierLocation == null) return [];
    
    return allDeliveries.where((delivery) {
      double distanceInKm = Geolocator.distanceBetween(
        _courierLocation!.latitude, _courierLocation!.longitude,
        delivery.pickupLocation.latitude, delivery.pickupLocation.longitude,
      ) / 1000; // Convert meters to kilometers
      
      return distanceInKm <= _operationalRadius;
    }).toList();
  }
  
  void _createDeliveryMarkers() {
    _deliveryMarkers = _deliveriesInRange.map((delivery) {
      return Marker(
        markerId: MarkerId(delivery.id),
        position: delivery.pickupLocation,
        infoWindow: InfoWindow(
          title: 'Pickup: ${delivery.pickupAddress}',
          snippet: 'Tap to view details',
        ),
        onTap: () => _showDeliveryDetails(delivery),
      );
    }).toSet();
  }
  
  void _showDeliveryDetails(Delivery delivery) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DeliveryDetailsSheet(
        delivery: delivery,
        onAccept: () {
          // Handle delivery acceptance TODO
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delivery #${delivery.id} accepted!')),
          );
          Navigator.pop(context);
        },
      ),
    );
  }
  
  Future<void> _updateOperationalRadius(double newRadius) async {
    setState(() {
      _operationalRadius = newRadius;
      if (_courierLocation != null) {
        _operationalAreaCircle = {
          Circle(
            circleId: CircleId('operationalArea'),
            center: _courierLocation!,
            radius: _operationalRadius * 1000,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 1,
          )
        };
      }
    });

    final resp = await DeliveryService.getDeliveries();
    final allDeliveries = resp.success ? List<Delivery>.from(resp.data!) : <Delivery>[];
    setState(() {
      _deliveriesInRange = _filterDeliveriesInRange(allDeliveries);
      _createDeliveryMarkers();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Deliveries'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Operational radius slider
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Radius: '),
                Expanded(
                  child: Slider(
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: '${_operationalRadius.round()} km',
                    value: _operationalRadius,
                    onChanged: _updateOperationalRadius,
                  ),
                ),
                Text('${_operationalRadius.round()} km'),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: _courierLocation == null
                ? Center(child: CircularProgressIndicator())
                : _showMap 
                    ? _buildMapView() 
                    : _buildListView(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _courierLocation!,
        zoom: 13,
      ),
      myLocationEnabled: true,
      markers: _deliveryMarkers,
      circles: _operationalAreaCircle,
    );
  }
  
  Widget _buildListView() {
    return _deliveriesInRange.isEmpty
        ? Center(child: Text('No deliveries available in your area'))
        : ListView.builder(
            itemCount: _deliveriesInRange.length,
            itemBuilder: (context, index) {
              final delivery = _deliveriesInRange[index];
              return DeliveryCard(
                delivery: delivery,
                onTap: () => _showDeliveryDetails(delivery),
              );
            },
          );
  }
}