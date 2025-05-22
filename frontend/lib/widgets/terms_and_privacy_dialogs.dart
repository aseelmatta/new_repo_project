import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyDialogs {
  static void showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Terms of Service',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Last Updated: May 22, 2025',
                        '',
                        isDate: true,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSection(
                        '1. Acceptance of Terms',
                        'By accessing and using the FETCH courier management application ("Service"), you accept and agree to be bound by the terms of this agreement. If you do not agree to these terms, you should not use this Service.',
                      ),
                      
                      _buildSection(
                        '2. Description of Service',
                        'FETCH is a platform that connects businesses needing delivery services with available couriers. Our Service facilitates the matching, tracking, and management of delivery requests between businesses and independent couriers.',
                      ),
                      
                      _buildSection(
                        '3. User Accounts',
                        '• You must create an account to use our Service\n• You are responsible for maintaining the confidentiality of your account\n• You must provide accurate and complete information\n• You may not share your account with others\n• You must notify us immediately of any unauthorized use',
                      ),
                      
                      _buildSection(
                        '4. User Responsibilities',
                        '• Businesses must provide accurate pickup and delivery information\n• Couriers must provide reliable delivery services\n• All users must comply with applicable laws and regulations\n• Users must treat other platform participants with respect\n• Package contents must be legal and safe to transport',
                      ),
                      
                      _buildSection(
                        '5. Payment and Fees',
                        'Delivery fees are determined by distance, package size, and demand. Payment processing is handled through our secure payment partners. Refunds may be issued for cancelled deliveries according to our refund policy.',
                      ),
                      
                      _buildSection(
                        '6. Liability and Insurance',
                        'FETCH acts as an intermediary platform. We are not responsible for loss, damage, or theft of packages during delivery. Users are encouraged to obtain appropriate insurance coverage for valuable items.',
                      ),
                      
                      _buildSection(
                        '7. Privacy and Data',
                        'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.',
                      ),
                      
                      _buildSection(
                        '8. Termination',
                        'We reserve the right to terminate or suspend accounts that violate these terms. Users may terminate their accounts at any time through the app settings.',
                      ),
                      
                      _buildSection(
                        '9. Changes to Terms',
                        'We may update these terms from time to time. Users will be notified of significant changes through the app or email.',
                      ),
                      
                      _buildSection(
                        '10. Contact Information',
                        'For questions about these terms, please contact us at support@fetchapp.com',
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'I Understand',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Last Updated: May 22, 2025',
                        '',
                        isDate: true,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSection(
                        '1. Information We Collect',
                        'We collect information you provide directly to us, such as:\n• Account information (name, email, phone number)\n• Business information (business name, address)\n• Location data for delivery services\n• Payment and transaction information\n• Communication data between users',
                      ),
                      
                      _buildSection(
                        '2. How We Use Your Information',
                        'We use your information to:\n• Provide and improve our delivery services\n• Process payments and transactions\n• Communicate with you about deliveries\n• Ensure platform safety and security\n• Send important updates and notifications\n• Analyze usage to improve our service',
                      ),
                      
                      _buildSection(
                        '3. Information Sharing',
                        'We may share your information with:\n• Other users necessary for delivery completion\n• Payment processors for transaction handling\n• Service providers who assist our operations\n• Law enforcement when legally required\n• We do not sell your personal information to third parties',
                      ),
                      
                      _buildSection(
                        '4. Location Information',
                        'We collect location data to:\n• Match couriers with nearby delivery requests\n• Provide real-time tracking for deliveries\n• Calculate accurate delivery fees and routes\n• You can control location sharing through your device settings',
                      ),
                      
                      _buildSection(
                        '5. Data Security',
                        'We implement security measures to protect your information including:\n• Encryption of sensitive data\n• Secure data transmission protocols\n• Regular security audits and updates\n• Limited access to personal information',
                      ),
                      
                      _buildSection(
                        '6. Data Retention',
                        'We retain your information for as long as your account is active or as needed to provide services. You may request deletion of your account and associated data at any time.',
                      ),
                      
                      _buildSection(
                        '7. Your Rights',
                        'You have the right to:\n• Access your personal information\n• Correct inaccurate information\n• Delete your account and data\n• Control communication preferences\n• Export your data',
                      ),
                      
                      _buildSection(
                        '8. Cookies and Analytics',
                        'We use cookies and similar technologies to improve your experience, analyze usage patterns, and provide personalized content.',
                      ),
                      
                      _buildSection(
                        '9. Children\'s Privacy',
                        'Our service is not intended for users under 18 years of age. We do not knowingly collect personal information from children.',
                      ),
                      
                      _buildSection(
                        '10. Changes to Privacy Policy',
                        'We may update this privacy policy periodically. We will notify users of significant changes through the app or email.',
                      ),
                      
                      _buildSection(
                        '11. Contact Us',
                        'For privacy-related questions or requests, contact us at:\nEmail: privacy@fetchapp.com\nPhone: +972 055-555-5555',
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'I Understand',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSection(String title, String content, {bool isDate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: isDate ? 12 : 16,
            fontWeight: isDate ? FontWeight.normal : FontWeight.bold,
            color: isDate ? Colors.grey[600] : Colors.black87,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}