import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/delivery_service.dart';



class CourierProfilePage extends StatefulWidget {
  const CourierProfilePage({super.key});

  @override
  State<CourierProfilePage> createState() => _CourierProfilePageState();
}

class _CourierProfilePageState extends State<CourierProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  String _photoUrl = '';
  // Personal Information Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();


  
  // Vehicle Information Controllers
  final TextEditingController _vehicleModelController = 
      TextEditingController(text: 'Honda Civic 2020');
  final TextEditingController _licensePlateController = 
      TextEditingController(text: 'ABC-1234');
  final TextEditingController _drivingLicenseController = 
      TextEditingController(text: 'DL123456789');
  
  // Emergency Contact Controllers
  final TextEditingController _emergencyContactController = 
      TextEditingController(text: 'Jane Doe');
  final TextEditingController _emergencyPhoneController = 
      TextEditingController(text: '+1 (555) 123-4567');

  // Settings
  String _selectedVehicleType = 'car';
  double _operationalRadius = 15.0;
  bool _isAvailable = true;
  bool _isAvailableWeekends = true;
  bool _hasInsurance = true;
  bool _canCarryFragileItems = true;
  bool _canCarryLargeItems = false;
  List<String> _selectedAvailability = ['Morning (10AM - 2PM)', 'Afternoon (2PM - 6PM)'];
  List<String> _selectedDeliveryTypes = ['Documents', 'Electronics', 'Food & Beverages'];

  // Performance metrics (mock data)
    double _totalEarnings   = 0.0;
    int    _totalDeliveries = 0;
    double _averageRating   = 0.0;
    String _memberSince     = '';

  final List<String> _vehicleTypes = ['car', 'motorcycle', 'bicycle', 'van'];
  final List<String> _availabilitySlots = [
    'Early Morning (6AM - 10AM)',
    'Morning (10AM - 2PM)',
    'Afternoon (2PM - 6PM)',
    'Evening (6PM - 10PM)',
  ];
  final List<String> _deliveryTypes = [
    'Documents',
    'Electronics',
    'Food & Beverages',
    'Clothing',
    'Fragile Items',
    'Medical Supplies',
  ];
  bool _isLoading = true; // for showing a spinner

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    // 1. Fetch the map from your backend
    final profile = await AuthService.getUserProfile();
    if (profile != null) {
      // 2. Fill each controller/variable
      _firstNameController.text      = profile['firstName']           ?? '';
      _lastNameController.text       = profile['lastName']            ?? '';
      _emailController.text          = profile['email']               ?? '';
      _phoneController.text          = profile['phone']               ?? '';
      _addressController.text        = profile['address']             ?? '';

      _selectedVehicleType           = profile['vehicleType']         ?? _selectedVehicleType;
      _vehicleModelController.text   = profile['vehicleModel']        ?? '';
      _licensePlateController.text   = profile['licensePlate']        ?? '';
      _drivingLicenseController.text = profile['drivingLicense']      ?? '';

      _emergencyContactController.text = profile['emergencyContact'] ?? '';
      _emergencyPhoneController.text   = profile['emergencyPhone']   ?? '';

      _isAvailableWeekends          = profile['isAvailableWeekends'] ?? _isAvailableWeekends;
      _hasInsurance                 = profile['hasInsurance']        ?? _hasInsurance;
      _canCarryFragileItems         = profile['canCarryFragileItems']?? _canCarryFragileItems;
      _canCarryLargeItems           = profile['canCarryLargeItems']  ?? _canCarryLargeItems;
      _operationalRadius            = (profile['operationalRadius'] as num?)?.toDouble()
                                      ?? _operationalRadius;

      _selectedAvailability         = List<String>.from(profile['availability'] ?? _selectedAvailability);
      _selectedDeliveryTypes        = List<String>.from(profile['deliveryTypes'] ?? _selectedDeliveryTypes);

      _photoUrl                     = profile['photoURL']             ?? '';
    }
    await _loadMetrics();
    setState(() => _isLoading = false);
  }

  /// Fetch all deliveries, then compute total count, earnings & avg rating
  Future<void> _loadMetrics() async {
    final resp = await DeliveryService.getDeliveries();
    if (!resp.success) return;

    // 1) get this courier’s UID however you have it
    final userId = FirebaseAuth.instance.currentUser?.uid;


    // 2) filter only deliveries assigned to me
    final mine = resp.data!
      .where((d) => d.assignedCourier == userId)
      .toList();

    // 3) total count
    final count = mine.length;

    // 4) sum up fees (assuming your Delivery model has `fee` double)
    final earnings = mine.fold<double>(0.0, (sum, d) => sum + (d.fee ?? 0.0));

    // 5) average rating (assuming a `rating` field on completed ones)
    final rated = mine.where((d) => d.rating != null).map((d) => d.rating!).toList();
    final avg = rated.isEmpty
      ? 0.0
      : rated.reduce((a, b) => a + b) / rated.length;

    // 6) update state so UI refreshes
    setState(() {
      _totalDeliveries = count;
      _totalEarnings   = earnings;
      _averageRating   = avg;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _drivingLicenseController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = {
      'firstName':       _firstNameController.text.trim(),
      'lastName':        _lastNameController.text.trim(),
      'email':           _emailController.text.trim(),
      'phone':           _phoneController.text.trim(),
      'address':         _addressController.text.trim(),

      'vehicleType':     _selectedVehicleType,
      'vehicleModel':    _vehicleModelController.text.trim(),
      'licensePlate':    _licensePlateController.text.trim(),
      'drivingLicense':  _drivingLicenseController.text.trim(),

      'emergencyContact':_emergencyContactController.text.trim(),
      'emergencyPhone':  _emergencyPhoneController.text.trim(),

      'isAvailableWeekends':    _isAvailableWeekends,
      'hasInsurance':           _hasInsurance,
      'canCarryFragileItems':   _canCarryFragileItems,
      'canCarryLargeItems':     _canCarryLargeItems,
      'operationalRadius':      _operationalRadius,

      'availability':   _selectedAvailability,
      'deliveryTypes':  _selectedDeliveryTypes,
      // you can include 'photoURL' if you let them change it
    };

    final success = await AuthService.updateUserProfile(updated);
    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red),
      );
    }
  }



  void _toggleAvailability() {
    setState(() {
      _isAvailable = !_isAvailable;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isAvailable ? 'You are now available for deliveries' : 'You are now offline'),
        backgroundColor: _isAvailable ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showEarningsDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Earnings Breakdown', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            _buildEarningsRow('Total Earnings', '\$${_totalEarnings.toStringAsFixed(2)}', Colors.green),
            _buildEarningsRow('This Month', '\$487.25', Colors.blue),
            _buildEarningsRow('This Week', '\$127.50', Colors.orange),
            _buildEarningsRow('Today', '\$23.75', Colors.purple),
            const SizedBox(height: 16),
            
            Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Expanded(
              child: ListView(
                children: [
                  _buildEarningsItem('Delivery #HIST001', '\$15.50', '2 hours ago'),
                  _buildEarningsItem('Delivery #HIST002', '\$18.25', 'Yesterday'),
                  _buildEarningsItem('Delivery #HIST003', '\$12.75', '2 days ago'),
                  _buildEarningsItem('Delivery #DEMO001', '\$21.00', '3 days ago'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to detailed earnings page
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Detailed Analytics'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Close the dialog first
            await AuthService.logout(); // Actually log out
            // Optionally navigate to welcome/login page
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            // Or if you use a widget: 
            // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => WelcomePage()), (route) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      if (_isLoading) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(child: CircularProgressIndicator()),
          );
        }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with Status
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green,
                          child: Text(
                            '${_firstNameController.text[0]}${_lastNameController.text[0]}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: _isAvailable ? Colors.green : Colors.red,
                            child: Icon(
                              _isAvailable ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_firstNameController.text} ${_lastNameController.text}',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text(_isAvailable ? 'AVAILABLE' : 'OFFLINE'),
                          backgroundColor: _isAvailable ? Colors.green : Colors.red,
                          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _toggleAvailability,
                          child: Text(
                            _isAvailable ? 'Go Offline' : 'Go Online',
                            style: TextStyle(color: _isAvailable ? Colors.red : Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Performance Overview
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Performance Overview',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Total Earned', '\$${_totalEarnings.toStringAsFixed(0)}', Icons.monetization_on),
                          _buildStatCard('Deliveries', '$_totalDeliveries', Icons.local_shipping),
                          _buildStatCard('Rating', '$_averageRating ⭐', Icons.star),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: _showEarningsDetails,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text('View Details', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'Member since $_memberSince',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Home Address',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Vehicle Information Section
              _buildSectionHeader('Vehicle Information'),
              
              if (_isEditing) ...[
                Text('Vehicle Type', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _vehicleTypes.map((type) {
                    final isSelected = _selectedVehicleType == type;
                    return FilterChip(
                      label: Text(type.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedVehicleType = type;
                        });
                      },
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ] else ...[
                _buildInfoRow('Vehicle Type:', _selectedVehicleType.toUpperCase()),
              ],
              
              _buildTextField(
                controller: _vehicleModelController,
                label: 'Vehicle Model',
                icon: Icons.directions_car,
              ),
              _buildTextField(
                controller: _licensePlateController,
                label: 'License Plate',
                icon: Icons.confirmation_number,
              ),
              _buildTextField(
                controller: _drivingLicenseController,
                label: 'Driving License Number',
                icon: Icons.credit_card,
              ),
              
              const SizedBox(height: 16),
              
              // Operational Settings
              _buildSectionHeader('Operational Settings'),
              
              Text('Operational Radius: ${_operationalRadius.toInt()} km', 
                   style: TextStyle(fontWeight: FontWeight.w500)),
              Slider(
                value: _operationalRadius,
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: Colors.green,
                onChanged: _isEditing ? (value) => setState(() => _operationalRadius = value) : null,
              ),
              
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Available on weekends'),
                value: _isAvailableWeekends,
                onChanged: _isEditing ? (value) => setState(() => _isAvailableWeekends = value ?? false) : null,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.green,
              ),
              
              CheckboxListTile(
                title: const Text('Have vehicle insurance'),
                value: _hasInsurance,
                onChanged: _isEditing ? (value) => setState(() => _hasInsurance = value ?? false) : null,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.green,
              ),
              
              CheckboxListTile(
                title: const Text('Can carry fragile items'),
                value: _canCarryFragileItems,
                onChanged: _isEditing ? (value) => setState(() => _canCarryFragileItems = value ?? false) : null,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.green,
              ),
              
              CheckboxListTile(
                title: const Text('Can carry large/heavy items'),
                value: _canCarryLargeItems,
                onChanged: _isEditing ? (value) => setState(() => _canCarryLargeItems = value ?? false) : null,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.green,
              ),
              
              const SizedBox(height: 24),
              
              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Emergency Contact Name',
                icon: Icons.contact_emergency,
              ),
              _buildTextField(
                controller: _emergencyPhoneController,
                label: 'Emergency Contact Phone',
                icon: Icons.phone_in_talk,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 24),
              
              // Account Settings Section
              _buildSectionHeader('Account Settings'),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notification Settings'),
                subtitle: const Text('Manage delivery and earning notifications'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy & Security'),
                subtitle: const Text('Manage account security settings'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to security settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and contact support'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to help page
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review),
                title: const Text('Rate the App'),
                subtitle: const Text('Help us improve FETCH'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open app rating dialog
                },
              ),
              
              const SizedBox(height: 24),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          enabled: _isEditing,
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsItem(String delivery, String amount, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          radius: 16,
          child: Icon(Icons.check, color: Colors.white, size: 16),
        ),
        title: Text(delivery, style: TextStyle(fontSize: 14)),
        subtitle: Text(time, style: TextStyle(fontSize: 12)),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}