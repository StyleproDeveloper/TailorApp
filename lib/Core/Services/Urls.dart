import 'package:flutter/foundation.dart' show kIsWeb;

class Urls {
  // Backend URL - automatically detects environment
  static String get baseUrl {
    // For web platform, try to detect hostname
    if (kIsWeb) {
      // On web, we can't use dart:html in mobile builds
      // So we'll just use production URL for now
      // Web-specific detection would need conditional imports
      return _getProductionUrl();
    }
    
    // For mobile platforms (Android/iOS), always use production backend
    return _getProductionUrl();
  }
  
  // Get production backend URL
  static String _getProductionUrl() {
    // Latest deployment: tailor-app-backend-1bfc2dnm3-stylepros-projects.vercel.app
    final url = 'https://tailor-app-backend-1bfc2dnm3-stylepros-projects.vercel.app';
    print('✅ Using PRODUCTION backend: $url');
    return url;
  }
  
  static const String shopName = '/shops';
  static const String customer = '/customer';
  static const String login = '/auth/login';
  static const String expense = '/expense';
  static const String otpVerify = '/auth/validate-otp';
  static const String addUsers = '/users';
  static const String addRole = '/roles';
  static const String addDress = '/dress-type';
  static const String addMeasurement = '/dresstype-measurement';
  static const String getMeasurement = '/measurement';
  static const String addDressPattern = '/dress-type-pattern';
  static const String getDressPattern = '/dress-pattern';
  static const String orderDressTypeMea = '/order-dressType-mea';
  static const String ordersSave = '/orders';
  static String get orders => '/orders';
  static const String billingTerm = '/billing-term';
  static const String userBranch = '/user-branch';
  static const String shopSetupComplete = '/shops/setup-complete';
  static const String orderMedia = '/order-media';
}
