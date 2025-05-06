import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome to Fetch',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect businesses with couriers for seamless deliveries',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildLoginButton(
                      context: context,
                      text: "Continue with Google",
                      icon: "assets/icons/google.png",
                      color: Colors.white,
                      textColor: Colors.black87,
                      onPressed: () {
                        // TODO: Implement Google login
                        print('Google login pressed');
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      context: context,
                      text: "Continue with Facebook",
                      icon: "assets/icons/facebook.png", // Add this asset
                      color: Colors.indigo,
                      textColor: Colors.white,
                      onPressed: () {
                        // TODO: Implement Facebook login
                        print('Facebook login pressed');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String text,
    required String icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}