import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'courier_dashboard.dart';
import '../services/auth_service.dart';

class CourierSetupPage extends StatefulWidget {
  final Map<String, String> userData;
  
  const CourierSetupPage({
    super.key,
    required this.userData,
  });

  @override
  State<CourierSetupPage> createState() => _CourierSetupPageState();
}

class _CourierSetupPageState extends State<CourierSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Courier-specific form controllers
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _drivingLicenseController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  
  String _selectedVehicleType = 'car';
  double _operationalRadius = 10.0;
  List<String> _selectedAvailability = [];
  List<String> _selectedDeliveryTypes = [];
  bool _hasInsurance = false;
  bool _canCarryFragileItems = false;
  bool _canCarryLargeItems = false;
  bool _isAvailableWeekends = false;

  final List<String> _vehicleTypes = [
    'car',
    'motorcycle',
    'bicycle',
    'van',
    'truck',
    'walking'
  ];

  final List<String> _availabilitySlots = [
    'Early Morning (6AM - 10AM)',
    'Morning (10AM - 2PM)',
    'Afternoon (2PM - 6PM)',
    'Evening (6PM - 10PM)',
    'Late Night (10PM - 6AM)',
  ];

  final List<String> _deliveryTypes = [
    'Documents',
    'Food & Beverages',
    'Electronics',
    'Clothing',
    'Fragile Items',
    'Heavy Items',
    'Medical Supplies',
    'Groceries',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _drivingLicenseController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedVehicleType.isNotEmpty;
      case 1:
        return _selectedAvailability.isNotEmpty;
      case 2:
        return _emergencyContactController.text.isNotEmpty && 
               _emergencyPhoneController.text.isNotEmpty;
      default:
        return true;
    }
  }

  void _completeSetup() {
    if (_formKey.currentState!.validate()) {
      // Combine all user data
      Map<String, dynamic> completeUserData = {
        ...widget.userData,
        'role': 'courier',
        'vehicleType': _selectedVehicleType,
        'vehicleModel': _vehicleModelController.text,
        'licensePlate': _licensePlateController.text,
        'drivingLicense': _drivingLicenseController.text,
        'operationalRadius': _operationalRadius,
        'availability': _selectedAvailability,
        'deliveryTypes': _selectedDeliveryTypes,
        'hasInsurance': _hasInsurance,
        'canCarryFragileItems': _canCarryFragileItems,
        'canCarryLargeItems': _canCarryLargeItems,
        'isAvailableWeekends': _isAvailableWeekends,
        'emergencyContact': _emergencyContactController.text,
        'emergencyPhone': _emergencyPhoneController.text,
      };
      
      // Save data and navigate to courier dashboard
      _saveUserData(completeUserData);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courier profile setup complete!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Show completion dialog
      _showCompletionDialog();
    }
  }

  void _saveUserData(Map<String, dynamic> userData) async {
    bool success = await AuthService.createUserProfile(userData);
    if (success) {
      print('✅ Courier user data saved to backend.');
    } else {
      print('❌ Failed to save courier user data to backend.');
      // Optionally show an error to the user
    }
  }


  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Deliver!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your courier profile is now complete. You can start accepting delivery requests and earning money right away!',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.of(context).pop(); // Close the dialog
                      // Navigate to courier dashboard
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const CourierDashboard()),
                        (route) => false, // This removes all previous routes
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Delivering',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Courier Setup',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildVehicleInfoStep(),
                  _buildAvailabilityStep(),
                  _buildEmergencyInfoStep(),
                ],
              ),
            ),
          ),
          
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentStep < 2 ? 'Next' : 'Complete Setup',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your delivery method',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Vehicle Type *',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _vehicleTypes.map((type) {
              final isSelected = _selectedVehicleType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = type),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getVehicleIcon(type),
                        color: isSelected ? Colors.green : Colors.grey[600],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (_selectedVehicleType != 'walking') ...[
            TextFormField(
              controller: _vehicleModelController,
              decoration: InputDecoration(
                labelText: 'Vehicle Model/Brand (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.directions_car),
                hintText: 'e.g., Honda Civic, Yamaha MT-15',
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _licensePlateController,
              decoration: InputDecoration(
                labelText: 'License Plate (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.confirmation_number),
                hintText: 'ABC-1234',
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (_selectedVehicleType == 'car' || _selectedVehicleType == 'motorcycle' || _selectedVehicleType == 'van' || _selectedVehicleType == 'truck') ...[
            TextFormField(
              controller: _drivingLicenseController,
              decoration: InputDecoration(
                labelText: 'Driving License Number (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Text(
            'Operational Radius: ${_operationalRadius.toInt()} km',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _operationalRadius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: Colors.green,
            onChanged: (value) => setState(() => _operationalRadius = value),
          ),
          Text(
            'How far are you willing to travel for deliveries?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          CheckboxListTile(
            title: const Text('I have vehicle insurance'),
            value: _hasInsurance,
            onChanged: (value) => setState(() => _hasInsurance = value ?? false),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability & Preferences',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When are you available to deliver?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Available Time Slots *',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._availabilitySlots.map((slot) {
            final isSelected = _selectedAvailability.contains(slot);
            return CheckboxListTile(
              title: Text(slot),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedAvailability.add(slot);
                  } else {
                    _selectedAvailability.remove(slot);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.green,
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Available on weekends'),
            subtitle: const Text('Saturday and Sunday'),
            value: _isAvailableWeekends,
            onChanged: (value) => setState(() => _isAvailableWeekends = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.green,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Delivery Types You Can Handle',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _deliveryTypes.map((type) {
              final isSelected = _selectedDeliveryTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDeliveryTypes.add(type);
                    } else {
                      _selectedDeliveryTypes.remove(type);
                    }
                  });
                },
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          CheckboxListTile(
            title: const Text('Can carry fragile items'),
            subtitle: const Text('Glass, electronics, delicate packages'),
            value: _canCarryFragileItems,
            onChanged: (value) => setState(() => _canCarryFragileItems = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.green,
          ),
          
          CheckboxListTile(
            title: const Text('Can carry large/heavy items'),
            subtitle: const Text('Furniture, appliances, bulk orders'),
            value: _canCarryLargeItems,
            onChanged: (value) => setState(() => _canCarryLargeItems = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Someone we can contact in case of emergency',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _emergencyContactController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
              hintText: 'Full name of emergency contact',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Emergency contact name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emergencyPhoneController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Phone *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
              hintText: '+1 (555) 123-4567',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Emergency contact phone is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This information is kept strictly confidential and will only be used in genuine emergencies.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'You\'re All Set!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'After completing setup, you\'ll be able to:\n• Browse nearby delivery requests\n• Accept deliveries that match your preferences\n• Track your earnings and performance\n• Build your courier reputation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.directions_car;
    }
  }
}