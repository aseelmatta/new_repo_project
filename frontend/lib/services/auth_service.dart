import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  // Update this with your actual backend URL
  static const String API_BASE_URL = 'http://10.0.2.2:5001'; // For Android emulator
  // static const String API_BASE_URL = 'http://127.0.0.1:5001'; // For iOS simulator
  // static const String API_BASE_URL = 'https://your-deployed-backend.com'; // For production
  
  static String? _userRole;
  static String? _token;
  static String? _uid;

  // Firebase Auth instance
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _uid = prefs.getString('user_uid');
    
    if (_token != null) {
      // Verify token with backend
      bool isValid = await verifyToken(_token!);
      if (!isValid) {
        await clearToken();
      }
    }
  }

  // Google Sign In
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(success: false, error: 'Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) {
        return AuthResult(success: false, error: 'Failed to sign in with Google');
      }

      // Get Firebase ID token
      final String? idToken = await user.getIdToken();
      
      // Send to backend for verification and user creation
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_token': googleAuth.accessToken,
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Save tokens
        await saveToken(idToken!);
        await saveUid(user.uid);
        
        return AuthResult(
          success: true,
          userData: {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          token: idToken,
        );
      } else {
        return AuthResult(success: false, error: 'Backend authentication failed');
      }
    } catch (e) {
      print('Google sign in error: $e');
      return AuthResult(success: false, error: 'Google sign in failed: $e');
    }
  }

  // Facebook Sign In
  static Future<AuthResult> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status != LoginStatus.success) {
        return AuthResult(success: false, error: 'Facebook login failed');
      }

      final AccessToken accessToken = result.accessToken!;
      
      // Create Firebase credential
      final credential = FacebookAuthProvider.credential(accessToken.tokenString);
      
      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) {
        return AuthResult(success: false, error: 'Failed to sign in with Facebook');
      }

      // Get Firebase ID token
      final String? idToken = await user.getIdToken();
      
      // Send to backend
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/facebook'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_token': accessToken.tokenString,
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        await saveToken(idToken!);
        await saveUid(user.uid);
        
        return AuthResult(
          success: true,
          userData: {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          token: idToken,
        );
      } else {
        return AuthResult(success: false, error: 'Backend authentication failed');
      }
    } catch (e) {
      print('Facebook sign in error: $e');
      return AuthResult(success: false, error: 'Facebook sign in failed: $e');
    }
  }

  // Save authentication token
  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }
  
  // Save user UID
  static Future<void> saveUid(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
    _uid = uid;
  }
  
  // Get stored authentication token
  static Future<String?> getToken() async {
    if (_token != null) return _token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }
  
  // Get stored UID
  static Future<String?> getUid() async {
    if (_uid != null) return _uid;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString('user_uid');
    return _uid;
  }
  
  // Clear authentication data (logout)
  static Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_uid');
    _token = null;
    _uid = null;
    _userRole = null;
    
    // Sign out from Firebase and social providers
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
  }
  
  // Verify token with backend
  static Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/health'),
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
  
  // Create user profile (after role selection)
  static Future<bool> createUserProfile(Map<String, dynamic> userData) async {
    try {
      String? token = await getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/createUserProfile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _userRole = userData['role'];
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Create user profile error: $e');
      return false;
    }
  }
  
  // Get user profile from backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String? token = await getToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('$API_BASE_URL/getUserProfile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _userRole = responseData['profile']['role'];
          return responseData['profile'];
        }
      }
    } catch (e) {
      print('Get user profile error: $e');
    }
    return null;
  }

  // Update user profile
  static Future<bool> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      String? token = await getToken();
      if (token == null) return false;
      
      final response = await http.put(
        Uri.parse('$API_BASE_URL/updateUserProfile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Update user profile error: $e');
      return false;
    }
  }
  
  // Get current user role
  static Future<String?> getUserRole() async {
    if (_userRole != null) return _userRole;
    
    final profile = await getUserProfile();
    if (profile != null) {
      _userRole = profile['role'];
      return _userRole;
    }
    return null;
  }
  
  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    String? token = await getToken();
    if (token == null) return false;
    return await verifyToken(token);
  }
  
  // Logout
  static Future<void> logout() async {
    try {
      String? token = await getToken();
      if (token != null) {
        // Optional: Call backend logout endpoint if you implement one
        await http.post(
          Uri.parse('$API_BASE_URL/logout'),
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