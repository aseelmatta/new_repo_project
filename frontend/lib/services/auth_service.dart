import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String API_BASE_URL = 'https://your-api-url.com/api'; // Replace with your actual API URL
  
  static String? _userRole;
  static String? _token;

  static Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    if (_token != null) {
      try {
        final response = await http.get(
          Uri.parse('$API_BASE_URL/auth/verify'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode != 200) {
          // Token is invalid, clear it
          await prefs.remove('auth_token');
          _token = null;
          _userRole = null;
        }
      } catch (e) {
        print('Token verification error: $e');
        _token = null;
        _userRole = null;
      }
    }
  }

  static Future<String?> getUserRole() async {
    if (_token == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/user/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _userRole = userData['role'];
        return _userRole;
      }
    } catch (e) {
      print('Get user role error: $e');
    }
    return null;
  }

  static Future<void> setUserRole(String role) async {
    _userRole = role;
  }
  
  // Save authentication token
  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Get stored authentication token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Clear authentication token (logout)
  static Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Verify token with backend
  static Future<bool> verifyToken(String token) async {
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
  
  // Get user profile from backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String? token = await getToken();
      if (token == null) return null;
      
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
      print('Get user profile error: $e');
    }
    return null;
  }
  
  // Google authentication
  static Future<AuthResult> authenticateWithGoogle(String accessToken, String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'access_token': accessToken,
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await saveToken(responseData['token']);
        
        return AuthResult(
          success: true,
          userData: responseData['user'],
          token: responseData['token'],
        );
      } else {
        final errorData = json.decode(response.body);
        return AuthResult(
          success: false,
          error: errorData['message'] ?? 'Authentication failed',
        );
      }
    } catch (e) {
      print('Google authentication error: $e');
      return AuthResult(
        success: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }
  
  // Facebook authentication
  static Future<AuthResult> authenticateWithFacebook(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/facebook'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await saveToken(responseData['token']);
        
        return AuthResult(
          success: true,
          userData: responseData['user'],
          token: responseData['token'],
        );
      } else {
        final errorData = json.decode(response.body);
        return AuthResult(
          success: false,
          error: errorData['message'] ?? 'Authentication failed',
        );
      }
    } catch (e) {
      print('Facebook authentication error: $e');
      return AuthResult(
        success: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }
  
  // Create user profile (after account setup)
  static Future<bool> createUserProfile(Map<String, dynamic> userData) async {
    try {
      String? token = await getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Create user profile error: $e');
      return false;
    }
  }
  
  // Update user profile
  static Future<bool> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      String? token = await getToken();
      if (token == null) return false;
      
      final response = await http.put(
        Uri.parse('$API_BASE_URL/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update user profile error: $e');
      return false;
    }
  }
  
  // Logout
  static Future<void> logout() async {
    try {
      String? token = await getToken();
      if (token != null) {
        // Optional: Call backend logout endpoint
        await http.post(
          Uri.parse('$API_BASE_URL/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await clearToken();
    }
  }
}

// Result class for authentication responses
class AuthResult {
  final bool success;
  final Map<String, dynamic>? userData;
  final String? token;
  final String? error;
  
  AuthResult({
    required this.success,
    this.userData,
    this.token,
    this.error,
  });
}