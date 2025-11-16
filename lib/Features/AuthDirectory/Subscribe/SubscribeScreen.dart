import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/GlobalVariables.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  String? selectedPlan;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trial Expired Message
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your 30-day trial period has ended',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please subscribe to continue using the app',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Subscription Plans
            Text(
              'Choose a Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorPalatte.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Monthly Plan
            _buildPlanCard(
              title: 'Monthly Plan',
              price: '₹999',
              period: 'per month',
              features: [
                'Full access to all features',
                'Unlimited orders',
                'Unlimited customers',
                'Priority support',
              ],
              value: 'monthly',
            ),
            const SizedBox(height: 16),

            // Yearly Plan
            _buildPlanCard(
              title: 'Yearly Plan',
              price: '₹9,999',
              period: 'per year',
              features: [
                'Full access to all features',
                'Unlimited orders',
                'Unlimited customers',
                'Priority support',
                'Save ₹1,989 (2 months free)',
              ],
              value: 'yearly',
              isRecommended: true,
            ),
            const SizedBox(height: 32),

            // Subscribe Button
            ElevatedButton(
              onPressed: selectedPlan == null || isLoading
                  ? null
                  : () => _handleSubscribe(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalatte.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Contact Support
            TextButton(
              onPressed: () {
                // TODO: Navigate to contact support
                CustomSnackbar.showSnackbar(
                  context,
                  'Contact support for assistance',
                  duration: const Duration(seconds: 2),
                );
              },
              child: Text(
                'Need help? Contact Support',
                style: TextStyle(
                  color: ColorPalatte.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required String value,
    bool isRecommended = false,
  }) {
    final isSelected = selectedPlan == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? ColorPalatte.primary
                : isRecommended
                    ? Colors.blue.shade300
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? ColorPalatte.primary.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      if (isRecommended) const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? ColorPalatte.primary
                              : Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: ColorPalatte.primary,
                    size: 28,
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? ColorPalatte.primary
                        : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isSelected
                            ? ColorPalatte.primary
                            : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    if (selectedPlan == null) {
      CustomSnackbar.showSnackbar(
        context,
        'Please select a subscription plan',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Implement subscription payment integration
      // For now, show a message
      await Future.delayed(const Duration(seconds: 1));
      
      CustomSnackbar.showSnackbar(
        context,
        'Subscription feature coming soon. Please contact support.',
        duration: const Duration(seconds: 3),
      );
      
      // In production, this would:
      // 1. Call payment gateway API
      // 2. Update shop subscription in backend
      // 3. Redirect to home screen
      
    } catch (e) {
      CustomSnackbar.showSnackbar(
        context,
        'Error processing subscription: $e',
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

