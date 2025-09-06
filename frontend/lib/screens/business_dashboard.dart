import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import 'business_chat_page.dart';
import 'business_profile_page.dart';
import 'delivery_tracking_page.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';

  List<Delivery> _deliveries = [];
  String _searchQuery = '';
  bool _showMapView = false;
  String _statusFilter = 'all';
  GoogleMapController? _mapController;
  int _currentIndex = 0;

  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDeliveries();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    final resp = await DeliveryService.getDeliveries();
    if (resp.success) {
      setState(() => _deliveries = resp.data!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading deliveries: ${resp.error}')),
      );
    }
  }

  void _showContactCourierDialog(BuildContext context, Delivery delivery) {
    const String courierPhone = '+1 (555) 987-6543';
    const String courierName = 'John Doe';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text('JD', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courierName, style: TextStyle(fontSize: 16)),
                    Text(
                      'Your Courier',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.phone, color: Colors.green),
                  ),
                  title: const Text('Call Courier'),
                  subtitle: Text(courierPhone),
                  onTap: () {
                    Navigator.pop(context);
                    _callCourier(courierPhone);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.sms, color: Colors.blue),
                  ),
                  title: const Text('Send SMS'),
                  subtitle: const Text('Send a text message'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendSMS(courierPhone);
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your courier is available 8 AM - 10 PM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _callCourier(String phoneNumber) async {
    // Remove formatting for actual calling
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showContactFallback(phoneNumber, 'call');
      }
    } catch (e) {
      _showContactFallback(phoneNumber, 'call');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: {
        'body':
            'Hi! This is regarding my delivery #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}. ',
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showContactFallback(phoneNumber, 'message');
      }
    } catch (e) {
      _showContactFallback(phoneNumber, 'message');
    }
  }

  void _showContactFallback(String phoneNumber, String action) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${action == 'call' ? 'Call' : 'Message'} Courier'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your courier\'s phone number:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phoneNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number copied!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy number',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can ${action} this number manually.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _showRatingDialog(Delivery delivery) {
    int overallRating = 5;
    int punctualityRating = 5;
    int professionalismRating = 5;
    int communicationRating = 5;
    TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          'JD',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rate Your Courier',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Delivery #${delivery.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overall Rating
                        Text(
                          'Overall Experience',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              onPressed:
                                  () =>
                                      setState(() => overallRating = index + 1),
                              icon: Icon(
                                index < overallRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        Text(
                          _getRatingText(overallRating),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _getRatingColor(overallRating),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),

                        // Detailed Ratings
                        Text(
                          'Rate Specific Aspects',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Punctuality
                        _buildDetailedRating(
                          'Punctuality',
                          'Was the courier on time?',
                          punctualityRating,
                          (rating) =>
                              setState(() => punctualityRating = rating),
                        ),

                        // Professionalism
                        _buildDetailedRating(
                          'Professionalism',
                          'How professional was the courier?',
                          professionalismRating,
                          (rating) =>
                              setState(() => professionalismRating = rating),
                        ),

                        // Communication
                        _buildDetailedRating(
                          'Communication',
                          'How was the communication?',
                          communicationRating,
                          (rating) =>
                              setState(() => communicationRating = rating),
                        ),

                        const SizedBox(height: 16),

                        // Feedback Text
                        Text(
                          'Additional Feedback (Optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: feedbackController,
                          decoration: InputDecoration(
                            hintText: 'Share your experience or suggestions...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.all(12),
                          ),
                          maxLines: 3,
                          maxLength: 200,
                        ),

                        const SizedBox(height: 12),

                        // Tip Option
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.monetization_on, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add a tip?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Show appreciation for great service',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showTipDialog(delivery, overallRating);
                                },
                                child: Text('Add Tip'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitRating(
                          delivery,
                          overallRating,
                          punctualityRating,
                          professionalismRating,
                          communicationRating,
                          feedbackController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit Rating'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildDetailedRating(
    String title,
    String subtitle,
    int rating,
    Function(int) onRatingChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRatingChanged(index + 1),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _submitRating(
    Delivery delivery,
    int overallRating,
    int punctualityRating,
    int professionalismRating,
    int communicationRating,
    String feedback,
  ) {
    // TODO: Send rating to backend
    print('Rating submitted:');
    print('Delivery: ${delivery.id}');
    print('Overall: $overallRating stars');
    print('Punctuality: $punctualityRating stars');
    print('Professionalism: $professionalismRating stars');
    print('Communication: $communicationRating stars');
    print('Feedback: $feedback');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Thank you! Your $overallRating-star rating has been submitted.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Receipt',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Show delivery receipt
          },
        ),
      ),
    );
  }

  void _showTipDialog(Delivery delivery, int rating) {
    List<double> tipAmounts = [2.0, 5.0, 10.0, 15.0];
    double? selectedTip;
    TextEditingController customTipController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Add a Tip'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your courier did a great job! Add a tip to show appreciation.',
                      ),
                      const SizedBox(height: 16),

                      // Preset tip amounts
                      Wrap(
                        spacing: 8,
                        children:
                            tipAmounts.map((amount) {
                              bool isSelected = selectedTip == amount;
                              return ChoiceChip(
                                label: Text('\$${amount.toStringAsFixed(0)}'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedTip = selected ? amount : null;
                                    customTipController.clear();
                                  });
                                },
                                selectedColor: Colors.green.withOpacity(0.2),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Or enter custom amount:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),

                      // Custom tip amount
                      TextField(
                        controller: customTipController,
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            selectedTip = null; // Clear preset selection
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        double tipAmount =
                            selectedTip ??
                            double.tryParse(customTipController.text) ??
                            0;
                        if (tipAmount > 0) {
                          Navigator.pop(context);
                          _processTip(delivery, tipAmount);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please select or enter a tip amount',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Add Tip'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _processTip(Delivery delivery, double amount) {
    // TODO: Process tip payment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you! \$${amount.toStringAsFixed(2)} tip added for your courier.',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
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
void _showDeliveryDetails(Delivery delivery) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIXED: Prevent overflow in the header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Use Expanded to prevent text overflow
              Expanded(
                flex: 3, // Give more space to the title
                child: Text(
                  'Delivery #${delivery.id}',
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis, // Add ellipsis for long IDs
                  maxLines: 1, // Ensure it stays on one line
                ),
              ),
              const SizedBox(width: 8), // Add some spacing
              // Use Flexible for the chip to wrap if needed
              Flexible(
                flex: 2, // Give less space to the chip
                child: Chip(
                  label: Text(
                    delivery.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12, // Slightly smaller font to ensure it fits
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent chip text overflow
                  ),
                  backgroundColor: _getStatusColor(delivery.status),
                ),
              ),
            ],
          ),
          

          const Divider(),
          const SizedBox(height: 8),
          
          // Make the rest of the content scrollable to prevent bottom overflow
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Delivery Details'),
                  _buildInfoRow('Pickup:', delivery.pickupAddress),
                  _buildInfoRow('Dropoff:', delivery.dropoffAddress),
                  _buildInfoRow('Description:', delivery.description),
                  _buildInfoRow('Created:', '2 hours ago'),
                  const SizedBox(height: 16),

                  if (delivery.status == 'in_progress' ||
                      delivery.status == 'accepted')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection('Courier Information'),
                        _buildInfoRow('Name:', 'John Doe'),
                        _buildInfoRow('Rating:', '4.8 ★'),
                        _buildInfoRow('Expected delivery:', '15:30'),
                        
                        // FIXED: Make buttons responsive to prevent overflow
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // If screen is narrow, stack buttons vertically
                            if (constraints.maxWidth < 350) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showContactCourierDialog(context, delivery);
                                      },
                                      icon: const Icon(Icons.message),
                                      label: const Text('Message Courier'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeliveryTrackingPage(
                                              delivery: delivery,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.location_on),
                                      label: const Text('Track Live'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Normal horizontal layout for wider screens
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showContactCourierDialog(context, delivery);
                                      },
                                      icon: const Icon(Icons.message),
                                      label: const Text('Message Courier'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeliveryTrackingPage(
                                              delivery: delivery,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.location_on),
                                      label: const Text('Track Live'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),

                  if (delivery.status == 'completed')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection('Delivery Summary'),
                        _buildInfoRow('Delivered at:', '15:32, May 20, 2025'),
                        _buildInfoRow('Courier:', 'John Doe'),
                        _buildInfoRow('Signature:', 'Available'),
                        _buildInfoRow('Rating:', 'Not rated yet'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showRatingDialog(delivery),
                            icon: const Icon(Icons.star),
                            label: const Text('Rate this Delivery'),
                          ),
                        ),
                      ],
                    ),

                  if (delivery.status == 'pending')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection('Pending Delivery'),
                        _buildInfoRow('Created at:', '13:15, May 21, 2025'),
                        _buildInfoRow(
                          'Status:',
                          'Waiting for courier assignment',
                        ),
                        const SizedBox(height: 16),
                        
                        // FIXED: Make cancel/edit buttons responsive
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 350) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Implement edit
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Details'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        print('[BusinessCancel] pressed for ${delivery.id}');
                                        final token = await AuthService.getToken();
                                        if (token == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Login required')),
                                          );
                                          return;
                                        }
                                        try {
                                          await DeliveryService.cancelDelivery(
                                            delivery.id,
                                            token,
                                          );
                                          await _loadDeliveries();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Order cancelled')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Cancel failed: $e'),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancel'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Implement edit
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Details'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        print('[BusinessCancel] pressed for ${delivery.id}');
                                        final token = await AuthService.getToken();
                                        if (token == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Login required')),
                                          );
                                          return;
                                        }
                                        try {
                                          await DeliveryService.cancelDelivery(
                                            delivery.id,
                                            token,
                                          );
                                          await _loadDeliveries();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Order cancelled')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Cancel failed: $e'),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancel'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  
                  // Add bottom padding to prevent content from being cut off
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildInfoSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCreateDeliveryForm() {
    bool selectingPickup = true;
    TextEditingController pickupController = TextEditingController();
    TextEditingController dropoffController = TextEditingController();
    TextEditingController recipientNameController = TextEditingController();
    TextEditingController recipientPhoneController = TextEditingController();
    TextEditingController instructionsController = TextEditingController();
    GoogleMapController? mapController;

    void showMapSelector(BuildContext context, bool isPickup) {
      selectingPickup = isPickup;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setModalState) => Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      children: [
                        AppBar(
                          title: Text(
                            'Select ${isPickup ? 'Pickup' : 'Dropoff'} Location',
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (selectingPickup &&
                                      _pickupLocation != null) {
                                    _pickupAddress =
                                        'Location at ${_pickupLocation!.latitude.toStringAsFixed(4)}, ${_pickupLocation!.longitude.toStringAsFixed(4)}';
                                    pickupController.text = _pickupAddress;
                                  } else if (!selectingPickup &&
                                      _dropoffLocation != null) {
                                    _dropoffAddress =
                                        'Location at ${_dropoffLocation!.latitude.toStringAsFixed(4)}, ${_dropoffLocation!.longitude.toStringAsFixed(4)}';
                                    dropoffController.text = _dropoffAddress;
                                  }
                                });
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'CONFIRM',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for a location...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                            ),
                            onSubmitted: (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Search functionality would connect to Places API',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(37.4219999, -122.0840575),
                              zoom: 14,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              mapController = controller;
                            },
                            markers: {
                              if (selectingPickup && _pickupLocation != null)
                                Marker(
                                  markerId: const MarkerId('pickup'),
                                  position: _pickupLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueGreen,
                                  ),
                                ),
                              if (!selectingPickup && _dropoffLocation != null)
                                Marker(
                                  markerId: const MarkerId('dropoff'),
                                  position: _dropoffLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                            },
                            onTap: (LatLng location) {
                              setModalState(() {
                                if (selectingPickup) {
                                  _pickupLocation = location;
                                } else {
                                  _dropoffLocation = location;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setFormState) => Container(
                  padding:
                      const EdgeInsets.all(16) +
                      EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Delivery',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pickupController,
                                decoration: const InputDecoration(
                                  hintText: 'Pickup address',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map, color: Colors.green),
                              onPressed: () => showMapSelector(context, true),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Dropoff Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dropoffController,
                                decoration: const InputDecoration(
                                  hintText: 'Dropoff address',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map, color: Colors.red),
                              onPressed: () => showMapSelector(context, false),
                            ),
                          ],
                        ),

                        if (_pickupLocation != null && _dropoffLocation != null)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    (_pickupLocation!.latitude +
                                            _dropoffLocation!.latitude) /
                                        2,
                                    (_pickupLocation!.longitude +
                                            _dropoffLocation!.longitude) /
                                        2,
                                  ),
                                  zoom: 12,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('pickup'),
                                    position: _pickupLocation!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueGreen,
                                    ),
                                    infoWindow: const InfoWindow(
                                      title: 'Pickup',
                                    ),
                                  ),
                                  Marker(
                                    markerId: const MarkerId('dropoff'),
                                    position: _dropoffLocation!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                    infoWindow: const InfoWindow(
                                      title: 'Dropoff',
                                    ),
                                  ),
                                },
                                polylines: {
                                  Polyline(
                                    polylineId: const PolylineId('route'),
                                    points: [
                                      _pickupLocation!,
                                      _dropoffLocation!,
                                    ],
                                    color: Colors.blue,
                                    width: 5,
                                  ),
                                },
                                liteModeEnabled: true,
                                zoomControlsEnabled: false,
                                scrollGesturesEnabled: false,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        Text(
                          'Package Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const TextField(
                          decoration: InputDecoration(
                            hintText:
                                'Package description (size, weight, contents, etc.)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Recipient Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: recipientNameController,
                          decoration: InputDecoration(
                            labelText: 'Recipient Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: recipientPhoneController,
                          decoration: InputDecoration(
                            labelText: 'Recipient Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Delivery Instructions (Optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: instructionsController,
                          decoration: InputDecoration(
                            hintText: 'Special instructions for the courier',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_pickupLocation == null ||
                                  _dropoffLocation == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select both pickup and dropoff locations',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Get values from text fields
                              final recipientName =
                                  recipientNameController.text.trim();
                              final recipientPhone =
                                  recipientPhoneController.text.trim();
                              final instructions =
                                  instructionsController.text.trim();

                              // (Optionally) Add validation for recipientName and recipientPhone here

                              // Call the API
                              final resp = await DeliveryService.createDelivery(
                                pickupLocation: {
                                  'lat': _pickupLocation!.latitude,
                                  'lng': _pickupLocation!.longitude,
                                },
                                dropoffLocation: {
                                  'lat': _dropoffLocation!.latitude,
                                  'lng': _dropoffLocation!.longitude,
                                },
                                recipientName: recipientName,
                                recipientPhone: recipientPhone,
                                instructions: instructions,
                              );

                              if (resp.success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Delivery created successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Reload deliveries!
                                await _loadDeliveries();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      resp.error ?? 'Failed to create delivery',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Create Delivery'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildDashboardPage() {
    final filteredDeliveries =
        _deliveries.where((delivery) {
          bool matchesSearch =
              delivery.pickupAddress.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              delivery.dropoffAddress.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              delivery.status.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          bool matchesFilter =
              _statusFilter == 'all' || delivery.status == _statusFilter;

          return matchesSearch && matchesFilter;
        }).toList();

    int pendingCount = _deliveries.where((d) => d.status == 'pending').length;
    int inProgressCount =
        _deliveries
            .where((d) => d.status == 'in_progress' || d.status == 'accepted')
            .length;
    int completedCount =
        _deliveries.where((d) => d.status == 'completed').length;
    int cancelledCount =
        _deliveries.where((d) => d.status == 'cancelled').length;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Pending', pendingCount, Colors.orange),
                    _buildStatCard('Active', inProgressCount, Colors.blue),
                    _buildStatCard('Completed', completedCount, Colors.green),
                    _buildStatCard('Cancelled', cancelledCount, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 30,
                    child: Row(
                      children: [
                        if (pendingCount > 0)
                          Expanded(
                            flex: pendingCount,
                            child: Container(color: Colors.orange),
                          ),
                        if (inProgressCount > 0)
                          Expanded(
                            flex: inProgressCount,
                            child: Container(color: Colors.blue),
                          ),
                        if (completedCount > 0)
                          Expanded(
                            flex: completedCount,
                            child: Container(color: Colors.green),
                          ),
                        if (cancelledCount > 0)
                          Expanded(
                            flex: cancelledCount,
                            child: Container(color: Colors.red),
                          ),
                        if (pendingCount +
                                inProgressCount +
                                completedCount +
                                cancelledCount ==
                            0)
                          Expanded(
                            child: Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('No deliveries yet'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search deliveries...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _showMapView = false),
                icon: const Icon(Icons.list),
                label: const Text('List View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_showMapView ? Colors.blue : Colors.grey,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showMapView = true),
                icon: const Icon(Icons.map),
                label: const Text('Map View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showMapView ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child:
              _showMapView
                  ? GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(37.4219999, -122.0840575),
                      zoom: 12,
                    ),
                    markers: {
                      ...filteredDeliveries.map(
                        (delivery) => Marker(
                          markerId: MarkerId(delivery.id),
                          position: delivery.pickupLocation,
                          infoWindow: InfoWindow(
                            title: 'Delivery #${delivery.id}',
                            snippet: delivery.status,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            _getMarkerHue(delivery.status),
                          ),
                          onTap: () => _showDeliveryDetails(delivery),
                        ),
                      ),
                    },
                    onMapCreated: (controller) => _mapController = controller,
                  )
                  : filteredDeliveries.isEmpty
                  ? const Center(child: Text('No deliveries found'))
                  : ListView.builder(
                    itemCount: filteredDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = filteredDeliveries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text('Delivery #${delivery.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From: ${delivery.pickupAddress}'),
                              Text('To: ${delivery.dropoffAddress}'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: _getProgressValue(delivery.status),
                                backgroundColor: Colors.grey[200],
                                color: _getStatusColor(delivery.status),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStatusIcon(delivery.status),
                                color: _getStatusColor(delivery.status),
                              ),
                              Text(
                                delivery.status,
                                style: TextStyle(
                                  color: _getStatusColor(delivery.status),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showDeliveryDetails(delivery),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'FETCH Dashboard'
              : _currentIndex == 1
              ? 'Support Chat'
              : 'Profile',
        ),
        actions:
            _currentIndex == 0
                ? [
                  IconButton(
                    icon: Icon(_showMapView ? Icons.list : Icons.map),
                    onPressed:
                        () => setState(() => _showMapView = !_showMapView),
                  ),
                ]
                : null,
      ),
      body:
          _pageController != null
              ? PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  _buildDashboardPage(),
                  const BusinessChatPage(),
                  const BusinessProfilePage(),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton.extended(
                onPressed: _showCreateDeliveryForm,
                label: const Text('New Delivery'),
                icon: const Icon(Icons.add),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Support',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
        return 0.2;
      case 'accepted':
        return 0.4;
      case 'in_progress':
        return 0.7;
      case 'completed':
        return 1.0;
      case 'cancelled':
        return 1.0;
      default:
        return 0.0;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'in_progress':
        return Icons.local_shipping;
      case 'accepted':
        return Icons.thumb_up;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  double _getMarkerHue(String status) {
    switch (status) {
      case 'completed':
        return BitmapDescriptor.hueGreen;
      case 'cancelled':
        return BitmapDescriptor.hueRed;
      case 'in_progress':
        return BitmapDescriptor.hueBlue;
      case 'accepted':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }
}
