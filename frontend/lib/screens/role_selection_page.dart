import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'business_setup_page.dart';
import 'courier_setup_page.dart';

class RoleSelectionPage extends StatefulWidget {
  final Map<String, String> userData;
  
  const RoleSelectionPage({
    super.key,
    required this.userData,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _continueWithRole() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to role-specific setup page
    Widget nextPage;
    switch (_selectedRole) {
      case 'business':
        nextPage = BusinessSetupPage(userData: widget.userData);
        break;
      case 'courier':
        nextPage = CourierSetupPage(userData: widget.userData);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Choose Your Role',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.userData['firstName']}!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How do you plan to use FETCH?',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Business Role Card
            _buildRoleCard(
              role: 'business',
              title: 'Business Owner',
              subtitle: 'I need delivery services for my business',
              description: 'Create delivery requests, track packages, and manage multiple deliveries for your business operations.',
              icon: Icons.business,
              color: Colors.blue,
              features: [
                'Create and manage delivery requests',
                'Track deliveries in real-time',
                'Manage multiple delivery addresses',
                'Rate and review couriers',
                'Access delivery history and analytics',
              ],
            ),

            const SizedBox(height: 16),

            // Courier Role Card
            _buildRoleCard(
              role: 'courier',
              title: 'Courier',
              subtitle: 'I want to deliver packages and earn money',
              description: 'Accept delivery requests, earn money, and provide reliable delivery services in your area.',
              icon: Icons.delivery_dining,
              color: Colors.green,
              features: [
                'Find delivery opportunities nearby',
                'Set your operational area and availability',
                'Get recommended deliveries',
                'Track your earnings and performance',
                'Build your reputation with ratings',
              ],
            ),

            const SizedBox(height: 32),

            // Note about changing roles
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Don\'t worry! You can change your role later in your profile settings.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _selectedRole != null ? _continueWithRole : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedRole != null 
                ? (_selectedRole == 'business' ? Colors.blue : Colors.green)
                : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _selectedRole != null 
                ? 'Continue as ${_selectedRole == 'business' ? 'Business Owner' : 'Courier'}'
                : 'Select a Role',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Key Features:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ),
    Expanded(
      child: Text(
        feature,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.grey[600],
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
    );
  }
}