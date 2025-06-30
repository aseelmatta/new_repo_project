import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/delivery.dart';
import 'auth_service.dart';

class DeliveryService {
  static const String API_BASE_URL = 'http://10.0.2.2:5001'; // Match your auth service

  // Create a new delivery
  static Future<ApiResponse<String>> createDelivery({
    required Map<String, double> pickupLocation,
    required Map<String, double> dropoffLocation,
    required String recipientName,
    required String recipientPhone,
    String instructions = '',
  }) async {
      print('🛠️ createDelivery() called with: '
        'pickup=$pickupLocation, dropoff=$dropoffLocation, '
        'recipient=$recipientName');
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse.error('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$API_BASE_URL/createDelivery'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'pickupLocation': {
            'lat': pickupLocation['lat'],
            'lng': pickupLocation['lng'],
          },
          'dropoffLocation': {
            'lat': dropoffLocation['lat'],
            'lng': dropoffLocation['lng'],
          },
          'recipientName': recipientName,
          'recipientPhone': recipientPhone,
          'instructions': instructions,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return ApiResponse.success(responseData['delivery_id']);
        }
        return ApiResponse.error(responseData['error'] ?? 'Failed to create delivery');
      }
      print('🛠️ createDelivery() HTTP ${response.statusCode}: ${response.body}');
      return ApiResponse.error('Failed to create delivery');
      
    } catch (e) {
      print('❌ createDelivery error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Get all deliveries for the current user
  static Future<ApiResponse<List<Delivery>>> getDeliveries() async {
    try {
      print('▶️ getDeliveries calling GET $API_BASE_URL/getDeliveries');

      String? token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse.error('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$API_BASE_URL/getDeliveries'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('◀️ getDeliveries response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> deliveriesJson = responseData['deliveries'];
          List<Delivery> deliveries = deliveriesJson.map((json) => Delivery.fromBackendJson(json)).toList();
          return ApiResponse.success(deliveries);
        }
        return ApiResponse.error(responseData['error'] ?? 'Failed to fetch deliveries');
      }
      return ApiResponse.error('Failed to fetch deliveries');
    } catch (e) {
      print('Get deliveries error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Get a specific delivery by ID
  static Future<ApiResponse<Delivery>> getDelivery(String deliveryId) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse.error('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$API_BASE_URL/getDelivery/$deliveryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Delivery delivery = Delivery.fromBackendJson(responseData['delivery']);
          return ApiResponse.success(delivery);
        }
        return ApiResponse.error(responseData['error'] ?? 'Delivery not found');
      }
      return ApiResponse.error('Failed to fetch delivery');
    } catch (e) {
      print('Get delivery error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }


static Future<void> cancelDelivery(String id, String token) async {
    print('[Service] DELETE /deleteDelivery/$id');
    
    final url = Uri.parse('$API_BASE_URL/deleteDelivery/$id');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // if you use tokens
      },
    );
    print('[Service] got ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel delivery: ${response.statusCode} ${response.body}');
    }
  }

  // Update delivery status (for couriers)
  static Future<ApiResponse<bool>> updateDeliveryStatus(String deliveryId, String status) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse.error('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$API_BASE_URL/updateDelivery/$deliveryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return ApiResponse.success(true);
        }
        return ApiResponse.error(responseData['error'] ?? 'Failed to update status');
      }
      return ApiResponse.error('Failed to update delivery status');
    } catch (e) {
      print('Update delivery status error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Update courier location
  static Future<ApiResponse<bool>> updateLocation(double lat, double lng) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse.error('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$API_BASE_URL/updateLocation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return ApiResponse.success(true);
        }
        return ApiResponse.error(responseData['error'] ?? 'Failed to update location');
      }
      return ApiResponse.error('Failed to update location');
    } catch (e) {
      print('Update location error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }
}

// Generic API Response class
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse._({required this.success, this.data, this.error});

  factory ApiResponse.success(T data) => ApiResponse._(success: true, data: data);
  factory ApiResponse.error(String error) => ApiResponse._(success: false, error: error);
}