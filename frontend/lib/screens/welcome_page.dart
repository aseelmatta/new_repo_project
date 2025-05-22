import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  
  // Your backend API base URL
  static const String API_BASE_URL = 'https://your-api-url.com/api'; // Replace with your actual API URL

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // Check if user already has a valid session
  Future<void> _checkExistingSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token != null) {
        // Verify token with your backend
        bool isValid = await _verifyToken(token);
        if (isValid) {
          // Get user data and navigate appropriately
          Map<String, dynamic>? userData = await _getUserData(token);
          if (userData != null) {
            _handleAuthenticatedUser(userData);
          }
        } else {
          // Token is invalid, clear it
          await prefs.remove('auth_token');
        }
      }
    } catch (e) {
      print('Error checking existing session: $e');
    }
  }

  // Verify token with your backend
  Future<bool> _verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/auth/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }

  // Get user data from your backend
  Future<Map<String, dynamic>?> _getUserData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Get user data error: $e');
    }
    return null;
  }

  // Handle authenticated user - check if setup is complete
  void _handleAuthenticatedUser(Map<String, dynamic> userData) {
    // Check if user has completed onboarding
    bool hasCompletedSetup = userData['setup_completed'] ?? false;
    
    if (hasCompletedSetup) {
      // Navigate to appropriate dashboard based on role
      String userRole = userData['role'] ?? 'business';
      _navigateToDashboard(userRole);
    } else {
      // Navigate to account setup for first-time users
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AccountSetupPage(
            email: userData['email'],
            displayName: userData['display_name'] ?? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
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
        // dashboard = const CourierDashboard();
        dashboard = const BusinessDashboard(); // Temporary fallback
        break;
      case 'admin':
        // dashboard = const AdminDashboard();
        dashboard = const BusinessDashboard(); // Temporary fallback
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
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Send the token to your backend for verification
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'access_token': googleAuth.accessToken,
          'id_token': googleAuth.idToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Save the JWT token from your backend
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['token']);
        
        print('Google sign in successful: ${responseData['user']['email']}');
        _handleAuthenticatedUser(responseData['user']);
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog('Google Sign In Failed', errorData['message'] ?? 'Authentication failed');
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
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Send the Facebook access token to your backend
        final response = await http.post(
          Uri.parse('$API_BASE_URL/auth/facebook'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'access_token': result.accessToken!.tokenString,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          // Save the JWT token from your backend
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['token']);
          
          print('Facebook sign in successful: ${responseData['user']['email']}');
          _handleAuthenticatedUser(responseData['user']);
        } else {
          final errorData = json.decode(response.body);
          _showErrorDialog('Facebook Sign In Failed', errorData['message'] ?? 'Authentication failed');
        }
      } else {
        print('Facebook sign in failed: ${result.status}');
        String errorMessage = '';
        switch (result.status) {
          case LoginStatus.cancelled:
            errorMessage = 'Login was cancelled';
            break;
          case LoginStatus.failed:
            errorMessage = 'Login failed. Please try again.';
            break;
          default:
            errorMessage = 'An unexpected error occurred';
        }
        _showErrorDialog('Facebook Sign In Failed', errorMessage);
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
                  'FETCHI', 
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                // In your welcome_page.dart, you can add temporary mock buttons:
ElevatedButton(
  onPressed: () {
    // Navigate directly to account setup for testing
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSetupPage(
          email: 'test@example.com',
          displayName: 'Test User',
        ),
      ),
    );
  },
  child: const Text('Test Flow (Skip Auth)'),
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