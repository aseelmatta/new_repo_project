import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Delivery {
  final String id;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng dropoffLocation;
  final String dropoffAddress;
  String status; // pending, accepted, in_progress, completed, cancelled
  final String description;
  
  // Additional fields for backend integration
  final double? fee;
  final double? rating;
  final String? recipientName;
  final String? recipientPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? assignedCourier;
  final String? createdBy;
  final String? instructions;
  
  Delivery({
    required this.id,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropoffLocation,
    required this.dropoffAddress,
    required this.status,
    required this.description,
    this.recipientName,
    this.recipientPhone,
    this.createdAt,
    this.updatedAt,
    this.assignedCourier,
    this.createdBy,
    this.instructions,
    this.fee,
    this.rating,
  });

  // Create from backend JSON response
  factory Delivery.fromBackendJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      pickupLocation: LatLng(
        json['pickupLocation']?['lat']?.toDouble() ?? 0.0,
        json['pickupLocation']?['lng']?.toDouble() ?? 0.0,
      ),
      pickupAddress: _formatLocationFromCoordinates(json['pickupLocation']),
      dropoffLocation: LatLng(
        json['dropoffLocation']?['lat']?.toDouble() ?? 0.0,
        json['dropoffLocation']?['lng']?.toDouble() ?? 0.0,
      ),
      dropoffAddress: _formatLocationFromCoordinates(json['dropoffLocation']),
      status: _mapBackendStatus(json['status']),
      description: json['instructions'] ?? json['description'] ?? '',
      recipientName: json['recipientName'],
      recipientPhone: json['recipientPhone'],
      createdAt: json['timestampCreated'] != null 
          ? DateTime.tryParse(json['timestampCreated']) 
          : null,
      updatedAt: json['timestampUpdated'] != null 
          ? DateTime.tryParse(json['timestampUpdated']) 
          : null,
      assignedCourier: json['assignedCourier'],
      createdBy: json['createdBy'],
      instructions: json['instructions'],
      fee: (json['fee'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  // Convert to JSON for sending to backend
  Map<String, dynamic> toBackendJson() {
    return {
      'pickupLocation': {
        'lat': pickupLocation.latitude,
        'lng': pickupLocation.longitude,
      },
      'dropoffLocation': {
        'lat': dropoffLocation.latitude,
        'lng': dropoffLocation.longitude,
      },
      'recipientName': recipientName ?? '',
      'recipientPhone': recipientPhone ?? '',
      'instructions': instructions ?? description,
      'status': status,
      'fee': fee,
      'rating': rating,
    };
  }

  // Create a copy with updated fields
  Delivery copyWith({
    String? id,
    LatLng? pickupLocation,
    String? pickupAddress,
    LatLng? dropoffLocation,
    String? dropoffAddress,
    String? status,
    String? description,
    String? recipientName,
    String? recipientPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedCourier,
    String? createdBy,
    String? instructions,
  }) {
    return Delivery(
      id: id ?? this.id,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      status: status ?? this.status,
      description: description ?? this.description,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedCourier: assignedCourier ?? this.assignedCourier,
      createdBy: createdBy ?? this.createdBy,
      instructions: instructions ?? this.instructions,
    );
  }

  // Helper methods
  static String _formatLocationFromCoordinates(Map<String, dynamic>? location) {
    if (location == null) return 'Unknown Location';
    
    // For now, just show coordinates. In a real app, you'd use reverse geocoding
    double lat = location['lat']?.toDouble() ?? 0.0;
    double lng = location['lng']?.toDouble() ?? 0.0;
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  static String _mapBackendStatus(String? backendStatus) {
    switch (backendStatus?.toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'accepted':
        return 'accepted';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
      case 'delivered':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  // Calculate distance between pickup and dropoff
  double get distance {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(dropoffLocation.latitude - pickupLocation.latitude);
    double dLng = _degreesToRadians(dropoffLocation.longitude - pickupLocation.longitude);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(pickupLocation.latitude)) * 
        math.cos(_degreesToRadians(dropoffLocation.latitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Estimate delivery time based on distance
  String get estimatedTime {
    double distanceKm = distance;
    double timeInHours = distanceKm / 30; // Assuming 30 km/h average speed
    int timeInMinutes = (timeInHours * 60).round();
    
    if (timeInMinutes < 60) {
      return '$timeInMinutes min';
    } else {
      int hours = timeInMinutes ~/ 60;
      int minutes = timeInMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isPickedUp => status == 'picked_up';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  // UI helpers
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'picked_up':
        return 'Picked Up';
      case 'in_progress':
        return 'In Transit';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}