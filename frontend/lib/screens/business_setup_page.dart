import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'business_dashboard.dart';

class BusinessSetupPage extends StatefulWidget {
  final Map<String, String> userData;
  
  const BusinessSetupPage({
    super.key,
    required this.userData,
  });

  @override
  State<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Business-specific form controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedBusinessType = 'retail';
  bool _hasMultipleLocations = false;
  bool _needsRegularDeliveries = false;
  List<String> _selectedDeliveryTypes = [];

  final List<String> _businessTypes = [
    'retail',
    'restaurant',
    'e-commerce',
    'healthcare',
    'logistics',
    'other'
  ];

  final List<String> _deliveryTypes = [
    'Same-day delivery',
    'Express delivery',
    'Standard delivery',
    'Scheduled delivery',
    'Bulk delivery',
    'Fragile items',
    'Food delivery',
    'Document delivery',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _taxIdController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
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
        return _businessNameController.text.isNotEmpty && 
               _businessAddressController.text.isNotEmpty;
      case 1:
        return _businessPhoneController.text.isNotEmpty;
      case 2:
        return _selectedDeliveryTypes.isNotEmpty;
      default:
        return true;
    }
  }

  void _completeSetup() {
    if (_formKey.currentState!.validate()) {
      // Combine all user data
      Map<String, dynamic> completeUserData = {
        ...widget.userData,
        'role': 'business',
        'businessName': _businessNameController.text,
        'businessType': _selectedBusinessType,
        'taxId': _taxIdController.text,
        'businessAddress': _businessAddressController.text,
        'businessPhone': _businessPhoneController.text,
        'website': _websiteController.text,
        'description': _descriptionController.text,
        'hasMultipleLocations': _hasMultipleLocations,
        'needsRegularDeliveries': _needsRegularDeliveries,
        'deliveryTypes': _selectedDeliveryTypes,
      };
      
      // Save data and navigate to business dashboard
      _saveUserData(completeUserData);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile setup complete!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to business dashboard
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => BusinessDashboard()),
      //   (route) => false,
      // );
      
      // For now, show completion dialog
      _showCompletionDialog();
    }
  }

  void _saveUserData(Map<String, dynamic> userData) {
    // TODO: Save to your backend/database
    print('Saving business user data: $userData');
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
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to FETCH!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your business profile has been set up successfully. You can now start creating delivery requests and managing your deliveries.',
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
                      // Navigate to BusinessDashboard
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const BusinessDashboard()),
                        (route) => false, // This removes all previous routes
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Dashboard',
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
          'Business Setup',
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
                      color: index <= _currentStep ? Colors.blue : Colors.grey[300],
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
                  _buildBusinessInfoStep(),
                  _buildContactPreferencesStep(),
                  _buildDeliveryPreferencesStep(),
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
                      backgroundColor: Colors.blue,
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

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your business',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              labelText: 'Business Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedBusinessType,
            decoration: InputDecoration(
              labelText: 'Business Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: _businessTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBusinessType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _businessAddressController,
            decoration: InputDecoration(
              labelText: 'Business Address *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: () {
                  // TODO: Implement location picker
                },
              ),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _taxIdController,
            decoration: InputDecoration(
              labelText: 'Tax ID / Business Registration (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.receipt_long),
            ),
          ),
          const SizedBox(height: 24),
          
          CheckboxListTile(
            title: const Text('We have multiple business locations'),
            value: _hasMultipleLocations,
            onChanged: (value) {
              setState(() {
                _hasMultipleLocations = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildContactPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Online Presence',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How can couriers and customers reach you?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _businessPhoneController,
            decoration: InputDecoration(
              labelText: 'Business Phone Number *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
              hintText: '+1 (555) 123-4567',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _websiteController,
            decoration: InputDecoration(
              labelText: 'Website (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.language),
              hintText: 'https://www.yourbusiness.com',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Business Description (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.description),
              hintText: 'Tell us what your business does...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This information helps couriers understand your business and provide better service.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.blue[700],
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

  Widget _buildDeliveryPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Preferences',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What types of deliveries do you need?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Select all that apply:',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
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
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          CheckboxListTile(
            title: const Text('We need regular scheduled deliveries'),
            subtitle: const Text('Daily, weekly, or monthly delivery schedules'),
            value: _needsRegularDeliveries,
            onChanged: (value) {
              setState(() {
                _needsRegularDeliveries = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          
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
                    const Icon(Icons.rocket_launch, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'You\'re Almost Ready!',
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
                  'Once you complete setup, you\'ll be able to:\n• Create your first delivery request\n• Browse available couriers\n• Track deliveries in real-time\n• Manage your delivery history',
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
}