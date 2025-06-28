import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/welcome_page.dart';
import 'package:frontend/services/auth_service.dart';


class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  bool _isLoading = true;

@override
void initState() {
  super.initState();
  _loadProfile();
}

Future<void> _loadProfile() async {
  final profile = await AuthService.getUserProfile();
  if (profile != null) {
    setState(() {
      _businessNameController.text   = profile['businessName']   ?? '';
      _businessTypeController.text   = profile['businessType']   ?? '';
      _taxIdController.text          = profile['taxId']          ?? '';
      _contactPersonController.text  = profile['contactPerson']  ?? '';
      _emailController.text          = profile['email']          ?? '';
      _phoneController.text          = profile['phone']          ?? '';
      _addressController.text        = profile['address']        ?? '';
      _selectedRole                  = profile['role']           ?? _selectedRole;
      _isLoading                     = false;
    });
  } else {
    setState(() => _isLoading = false);
  }
}

  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  
  // Controllers for form fields
  final TextEditingController _businessNameController = 
      TextEditingController(text: 'ABC Logistics Ltd.');
  final TextEditingController _contactPersonController = 
      TextEditingController(text: 'John Smith');
  final TextEditingController _emailController = 
      TextEditingController(text: 'john.smith@abclogistics.com');
  final TextEditingController _phoneController = 
      TextEditingController(text: '+1 (555) 123-4567');
  final TextEditingController _addressController = 
      TextEditingController(text: '123 Business Ave, Suite 100\nNew York, NY 10001');
  final TextEditingController _businessTypeController = 
      TextEditingController(text: 'E-commerce');
  final TextEditingController _taxIdController = 
      TextEditingController(text: 'EIN-12-3456789');

  String _selectedRole = 'business'; // business, courier, admin

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessTypeController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

 Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;
  final updated = {
    'businessName':  _businessNameController.text.trim(),
    'businessType':  _businessTypeController.text.trim(),
    'taxId':         _taxIdController.text.trim(),
    'contactPerson': _contactPersonController.text.trim(),
    'email':         _emailController.text.trim(),
    'phone':         _phoneController.text.trim(),
    'address':       _addressController.text.trim(),
    'role':          _selectedRole,
  };
  final success = await AuthService.updateUserProfile(updated);
  if (success) {
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green)
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red)
    );
  }
}

  void _showRoleChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Account Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Warning: Changing your role will affect what features you can access. Are you sure you want to continue?',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'business', child: Text('Business')),
                DropdownMenuItem(value: 'courier', child: Text('Courier')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Role changed to $_selectedRole. Please restart the app.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Change Role', style: TextStyle(color: Colors.white)),
          ),
        ],
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
              Navigator.pop(context); // Close the dialog first (optional, but looks better)
              await AuthService.logout(); // Actually log out
              // Now send user to the welcome/login page and clear the stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => WelcomePage()), // Replace with your welcome/login page widget
                (route) => false,
              );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('SAVE', style: TextStyle(color: Colors.white)),
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
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Text(
                        _businessNameController.text.isNotEmpty 
                            ? _businessNameController.text[0].toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _businessNameController.text,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(_selectedRole.toUpperCase()),
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Business Information Section
              _buildSectionHeader('Business Information'),
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _businessTypeController,
                label: 'Business Type',
                icon: Icons.category,
              ),
              _buildTextField(
                controller: _taxIdController,
                label: 'Tax ID / EIN',
                icon: Icons.receipt_long,
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              _buildTextField(
                controller: _contactPersonController,
                label: 'Contact Person',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Contact person is required';
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
                label: 'Business Address',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Account Settings Section
              _buildSectionHeader('Account Settings'),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Change Role'),
                subtitle: Text('Current role: $_selectedRole'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showRoleChangeDialog,
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Manage notification preferences'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy & Security'),
                subtitle: const Text('Manage account security'),
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
              
              const SizedBox(height: 24),
              
              // App Information
              _buildSectionHeader('App Information'),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('Version 1.0.0'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Show about dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to terms
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
              
              const SizedBox(height: 32),
              
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
          color: Colors.blue,
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
}