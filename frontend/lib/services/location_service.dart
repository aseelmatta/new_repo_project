import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  // Google Geocoding API key - replace with your actual key
  static const String GOOGLE_GEOCODING_API_KEY = 'AIzaSyBIHDIjMDitDD-JFHllxBQNnUKOxm5Mz50';
  
  /// Get current location coordinates
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please allow location access in your device settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable location access in your device settings.');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    }
  }

  /// Convert coordinates to human-readable address using reverse geocoding
static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
  try {
    // REPLACE 'YOUR_ACTUAL_API_KEY' with your real Google API key
    const String apiKey = 'AIzaSyBIHDIjMDitDD-JFHllxBQNnUKOxm5Mz50';
    
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
        // Get the formatted address from the first result
        String formattedAddress = data['results'][0]['formatted_address'];
        return formattedAddress;
      } else if (data['status'] == 'ZERO_RESULTS') {
        return 'Address not found for this location';
      } else {
        throw Exception('Geocoding failed: ${data['status']}');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error getting address: $e');
    
    // Fallback to coordinates if API fails
    return 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

  /// Get current address (combines location detection and reverse geocoding)
  static Future<String> getCurrentAddress() async {
    try {
      Position? position = await getCurrentLocation();
      if (position != null) {
        return await getAddressFromCoordinates(position.latitude, position.longitude);
      }
      throw Exception('Unable to get current location');
    } catch (e) {
      print('Error getting current address: $e');
      rethrow;
    }
  }

  /// Show location permission dialog with instructions
  static void showLocationPermissionDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Access Needed'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To detect your current address, we need access to your location.'),
            SizedBox(height: 12),
            Text('Please:'),
            SizedBox(height: 8),
            Text('1. Enable location services on your device'),
            Text('2. Allow FETCH to access your location'),
            Text('3. Make sure you\'re in an area with good GPS signal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Check if location services are available
  static Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied && permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }
}