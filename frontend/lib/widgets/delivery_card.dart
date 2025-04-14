// a simple delivery card widget for the list view
import 'package:flutter/material.dart';
import '../models/delivery.dart';

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;
  
  const DeliveryCard({
    Key? key,
    required this.delivery,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery #${delivery.id}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('From: ${delivery.pickupAddress}'),
              Text('To: ${delivery.dropoffAddress}'),
              Text('Package: ${delivery.description}'),
            ],
          ),
        ),
      ),
    );
  }
}