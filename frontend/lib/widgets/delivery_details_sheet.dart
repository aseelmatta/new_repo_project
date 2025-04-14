// delivery details bottom sheet
import 'package:flutter/material.dart';
import '../models/delivery.dart';

class DeliveryDetailsSheet extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onAccept;
  
  const DeliveryDetailsSheet({
    Key? key,
    required this.delivery,
    required this.onAccept,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery #${delivery.id}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text('From: ${delivery.pickupAddress}'),
          Text('To: ${delivery.dropoffAddress}'),
          Text('Package: ${delivery.description}'),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAccept,
                child: Text('Accept Delivery'),
              ),
            ],
          )
        ],
      ),
    );
  }
}