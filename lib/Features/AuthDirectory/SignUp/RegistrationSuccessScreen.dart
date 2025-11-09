import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Routes/App_route.dart';
import 'package:url_launcher/url_launcher.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(title: const Text('Registration Success')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ColorPalatte.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: ColorPalatte.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              
              // Thank You Message
              const Text(
                'Thanks for registering with Style Pro!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorPalatte.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Setup Complete Message
              const Text(
                'We have set you up successfully.',
                style: TextStyle(
                  fontSize: 18,
                  color: ColorPalatte.gray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalatte.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: ColorPalatte.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Divider with "OR"
              Row(
                children: [
                  Expanded(child: Divider(color: ColorPalatte.borderGray)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: ColorPalatte.gray,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: ColorPalatte.borderGray)),
                ],
              ),
              const SizedBox(height: 32),
              
              // Help Text
              const Text(
                'Need help with onboarding?',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorPalatte.gray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Phone Number Button
              InkWell(
                onTap: () => _makePhoneCall('+919731033833'), // Update with actual support number
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorPalatte.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone,
                        color: ColorPalatte.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Call: +91 97310 33833',
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorPalatte.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

