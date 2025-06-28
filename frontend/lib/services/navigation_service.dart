import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  /// Show notification settings dialog
  static void showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.blue),
            SizedBox(width: 8),
            Text('Notification Settings'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            bool pushNotifications = true;
            bool emailNotifications = true;
            bool smsNotifications = false;
            bool deliveryUpdates = true;
            bool promotionalOffers = false;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Get instant updates on your phone'),
                  value: pushNotifications,
                  onChanged: (value) => setState(() => pushNotifications = value),
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive updates via email'),
                  value: emailNotifications,
                  onChanged: (value) => setState(() => emailNotifications = value),
                ),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  subtitle: const Text('Text message alerts'),
                  value: smsNotifications,
                  onChanged: (value) => setState(() => smsNotifications = value),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Delivery Updates'),
                  subtitle: const Text('Status changes and tracking'),
                  value: deliveryUpdates,
                  onChanged: (value) => setState(() => deliveryUpdates = value),
                ),
                SwitchListTile(
                  title: const Text('Promotional Offers'),
                  subtitle: const Text('Special deals and discounts'),
                  value: promotionalOffers,
                  onChanged: (value) => setState(() => promotionalOffers = value),
                ),
              ],
            );
          },
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
                const SnackBar(
                  content: Text('Notification settings saved!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  /// Show privacy and security settings
  static void showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Privacy & Security'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Privacy Settings'),
              subtitle: const Text('Control what others can see'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showPrivacyDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently remove your account'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog(context);
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show help and support options
  static void showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.orange),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text('Live Chat Support'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening live chat...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@fetchapp.com'),
              onTap: () => _launchEmail('support@fetchapp.com'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+972 055-555-5555'),
              onTap: () => _launchPhone('+972055555555'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                Navigator.pop(context);
                _showFAQ(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report a Bug'),
              subtitle: const Text('Tell us about issues you found'),
              onTap: () {
                Navigator.pop(context);
                _showBugReportDialog(context);
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show app rating dialog
  static void showAppRating(BuildContext context) {
    int rating = 5;
    TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Rate FETCH'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate your experience with FETCH?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Additional feedback (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                    content: Text('Thank you for your $rating-star rating!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show about app dialog
  static void showAboutApp(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FETCH',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 32),
      ),
      children: [
        const Text('FETCH is a modern courier management system that connects businesses with reliable couriers for efficient package delivery.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Real-time delivery tracking'),
        const Text('• Smart courier matching'),
        const Text('• AI-powered customer support'),
        const Text('• Comprehensive analytics'),
        const SizedBox(height: 16),
        const Text('© 2025 FETCH Team. All rights reserved.'),
      ],
    );
  }

  // Private helper methods
  static void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
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
                const SnackBar(content: Text('Password changed successfully!')),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  static void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            bool showProfile = true;
            bool showLocation = false;
            bool allowContact = true;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Show Profile to Others'),
                  value: showProfile,
                  onChanged: (value) => setState(() => showProfile = value),
                ),
                SwitchListTile(
                  title: const Text('Share Location'),
                  value: showLocation,
                  onChanged: (value) => setState(() => showLocation = value),
                ),
                SwitchListTile(
                  title: const Text('Allow Contact'),
                  value: allowContact,
                  onChanged: (value) => setState(() => allowContact = value),
                ),
              ],
            );
          },
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
                const SnackBar(content: Text('Privacy settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This action cannot be undone. Deleting your account will:'),
            SizedBox(height: 8),
            Text('• Remove all your personal data'),
            Text('• Cancel any active deliveries'),
            Text('• Delete your delivery history'),
            Text('• Revoke access to all FETCH services'),
            SizedBox(height: 16),
            Text('Are you sure you want to proceed?'),
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
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showFAQ(BuildContext context) {
    final faqs = [
      {'question': 'How do I track my delivery?', 'answer': 'Go to your dashboard and click "Track Live" on any active delivery.'},
      {'question': 'How are delivery fees calculated?', 'answer': 'Fees are based on distance, package size, and demand in your area.'},
      {'question': 'What if my courier is late?', 'answer': 'You can message the courier directly or contact our support team.'},
      {'question': 'How do I cancel a delivery?', 'answer': 'You can cancel pending deliveries from your dashboard before courier acceptance.'},
      {'question': 'Is my payment information secure?', 'answer': 'Yes, we use industry-standard encryption to protect all payment data.'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return ExpansionTile(
                title: Text(faqs[index]['question']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(faqs[index]['answer']!),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showBugReportDialog(BuildContext context) {
    final TextEditingController bugController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the issue you encountered:'),
            const SizedBox(height: 16),
            TextField(
              controller: bugController,
              decoration: const InputDecoration(
                labelText: 'Bug description',
                border: OutlineInputBorder(),
                hintText: 'What happened? What did you expect to happen?',
              ),
              maxLines: 4,
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
                const SnackBar(
                  content: Text('Bug report submitted. Thank you!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=FETCH Support Request',
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      print('Could not launch email: $e');
    }
  }

  static Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      print('Could not launch phone: $e');
    }
  }
}