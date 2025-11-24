import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/GlobalVariables.dart';

class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if shop is in trial period
    if (GlobalVariables.subscriptionType != 'Trial' && 
        GlobalVariables.subscriptionType != 'trial') {
      return const SizedBox.shrink();
    }
    
    if (GlobalVariables.trialEndDate == null || GlobalVariables.trialEndDate!.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final trialEndDateStr = GlobalVariables.trialEndDate!;
      final now = DateTime.now();
      DateTime endDate;
      
      // Try parsing ISO format first (e.g., "2024-01-15T00:00:00.000Z")
      try {
        endDate = DateTime.parse(trialEndDateStr);
      } catch (e) {
        // If parsing fails, try other formats or return empty
        print('⚠️ Error parsing trial end date: $trialEndDateStr');
        return const SizedBox.shrink();
      }
      
      final difference = endDate.difference(now).inDays;

      // Only show banner if trial hasn't ended
      if (difference < 0) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.red.shade700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trial period has ended',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      // Show warning if less than 7 days remaining
      final isWarning = difference <= 7;
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isWarning ? Colors.orange.shade700 : Colors.blue.shade700,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWarning ? Icons.warning : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Trial ends in ${difference} ${difference == 1 ? 'day' : 'days'}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // If there's any error, don't show the banner
      print('⚠️ Error in TrialBanner: $e');
      return const SizedBox.shrink();
    }
  }
}

