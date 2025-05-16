import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/courier_dashboard.dart';
import 'screens/business_dashboard.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Courier Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: AuthService.getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            final userRole = snapshot.data;
            if (userRole == null) {
              return const WelcomePage();
            } else if (userRole == 'courier') {
              return const CourierDashboard();
            } else if (userRole == 'business') {
              return const BusinessDashboard();
            } else {
              // Handle unexpected role or error
              return const WelcomePage();
            }
          }
        },
      ),
    );
  }
}
