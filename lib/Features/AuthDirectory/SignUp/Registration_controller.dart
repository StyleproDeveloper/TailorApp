import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a provider for the Map of TextEditingController
final registrationControllerProvider = Provider<Map<String, TextEditingController>>((ref) {
  return {
    'name': TextEditingController(),
    'shopName': TextEditingController(),
    'code': TextEditingController(),
    'shopType': TextEditingController(),
    'mobile': TextEditingController(),
    'secondaryMobile': TextEditingController(),
    'email': TextEditingController(),
    'website': TextEditingController(),
    'instagram': TextEditingController(),
    'facebook': TextEditingController(),
    'addressLine1': TextEditingController(),
    'street': TextEditingController(),
    'city': TextEditingController(),
    'postalCode': TextEditingController(),
  };
});

// Clean up all controllers when no longer needed
final registrationControllerCleanupProvider = Provider<void>((ref) {
  ref.onDispose(() {
    ref.read(registrationControllerProvider).values.forEach((controller) => controller.dispose());
  });
});
