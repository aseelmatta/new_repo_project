import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/terms_and_privacy_dialogs.dart';
import 'account_setup_page.dart';
import 'business_dashboard.dart';
import 'courier_dashboard.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // Check if user already has a valid session
  Future<void> _checkExistingSession() async {
    try {
      bool isAuthenticated = await AuthService.isAuthenticated();
      if (isAuthenticated) {
        // Get user profile to check if setup is complete
        Map<String, dynamic>? profile = await AuthService.getUserProfile();
        if (profile != null) {
          _handleAuthenticatedUser(profile);
        }
      }
    } catch (e) {
      print('Error checking existing session: $e');
    }
  }

  // Handle authenticated user - check if setup is complete
  void _handleAuthenticatedUser(Map<String, dynamic> userData) {
    // Check if user has completed role setup
    String? userRole = userData['role'];
    
    if (userRole != null) {
      // User has completed setup, navigate to appropriate dashboard
      _navigateToDashboard(userRole);
    } else {
      // User needs to complete setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AccountSetupPage(
            email: userData['email'],
            displayName: userData['displayName'] ?? '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
          ),
        ),
      );
    }
  }

  // Navigate to appropriate dashboard based on role
  void _navigateToDashboard(String role) {
    Widget dashboard;
    switch (role) {
      case 'business':
        dashboard = const BusinessDashboard();
        break;
      case 'courier':
        dashboard = const CourierDashboard();
        break;
      default:
        dashboard = const BusinessDashboard();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
    );
  }

  // Google Sign In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      AuthResult result = await AuthService.signInWithGoogle();
      
      if (result.success) {
        print('Google sign in successful: ${result.userData?['email']}');
        
        // Check if user has profile setup
        Map<String, dynamic>? profile = await AuthService.getUserProfile();
        
        if (profile != null && profile['role'] != null) {
          // User has completed setup
          _navigateToDashboard(profile['role']);
        } else {
          // New user or incomplete setup - go to account setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AccountSetupPage(
                email: result.userData?['email'],
                displayName: result.userData?['displayName'],
              ),
            ),
          );
        }
      } else {
        _showErrorDialog('Google Sign In Failed', result.error ?? 'Authentication failed');
      }
    } catch (e) {
      print('Google sign in error: $e');
      _showErrorDialog('Google Sign In Failed', 'Please check your internet connection and try again.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Facebook Sign In
  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      AuthResult result = await AuthService.signInWithFacebook();
      
      if (result.success) {
        print('Facebook sign in successful: ${result.userData?['email']}');
        
        // Check if user has profile setup
        Map<String, dynamic>? profile = await AuthService.getUserProfile();
        
        if (profile != null && profile['role'] != null) {
          // User has completed setup
          _navigateToDashboard(profile['role']);
        } else {
          // New user or incomplete setup - go to account setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AccountSetupPage(
                email: result.userData?['email'],
                displayName: result.userData?['displayName'],
              ),
            ),
          );
        }
      } else {
        _showErrorDialog('Facebook Sign In Failed', result.error ?? 'Authentication failed');
      }
    } catch (e) {
      print('Facebook sign in error: $e');
      _showErrorDialog('Facebook Sign In Failed', 'Please check your internet connection and try again.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple.shade100, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'WELCOME TO',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'FETCH', 
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'continue with-',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Show loading indicator if authenticating
                      if (_isLoading) 
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        )
                      else ...[
                        _buildLoginButton(
                          context: context,
                          imagePath: "assets/icons/google.png",
                          color: Colors.white,
                          onPressed: _signInWithGoogle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLoginButton(
                          context: context,
                          imagePath: "assets/icons/facebook.png",
                          color: Colors.blue,
                          onPressed: _signInWithFacebook,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Development/Testing buttons (remove in production)
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Development Testing:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSetupPage(
                            email: 'test@example.com',
                            displayName: 'Test User',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                    child: const Text('Skip Auth (Testing)'),
                  ),
                  const SizedBox(height: 24),
                ],
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            TermsAndPrivacyDialogs.showTermsOfService(context);
                          },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.pink,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            TermsAndPrivacyDialogs.showPrivacyPolicy(context);
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String imagePath, 
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            imagePath,
            width: 30,
            height: 30,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if image doesn't exist
              return Icon(
                imagePath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
                size: 30,
                color: color == Colors.white ? Colors.grey[700] : Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}