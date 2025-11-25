import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// Conditional import for web
import 'Urls_web.dart' if (dart.library.io) 'Urls_stub.dart';

class Urls {
  // Detect environment and set backend URL accordingly
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform - detect production vs localhost
      try {
        final hostname = getWebHostname();
        final isLocalhost = hostname == 'localhost' || 
                           hostname == '127.0.0.1' || 
                           hostname.isEmpty;
        
        if (isLocalhost) {
          if (kDebugMode) {
            print('Localhost detected - Using local backend');
          }
          return 'http://localhost:5500';
        } else {
          // Production - use Vercel proxy to avoid mixed content issues
          // Vercel rewrites will proxy API requests to AWS EB backend
          // This allows HTTPS frontend to communicate with HTTP backend
          final prodUrl = ''; // Empty string means use same origin (Vercel will proxy)
          if (kDebugMode) {
            print('Production detected - Using Vercel proxy to AWS EB backend');
          }
          return prodUrl;
        }
      } catch (e) {
        // Fallback to localhost if detection fails
        if (kDebugMode) {
          print('Error detecting environment, using localhost: $e');
        }
        return 'http://localhost:5500';
      }
    } else {
      // Mobile platform - use localhost for development
      return 'http://localhost:5500';
    }
  }
  
  // Log on first access (only in debug mode)
  static String get baseUrlGetter {
    final url = baseUrl;
    // Only log in debug mode for production readiness
    if (kDebugMode) {
      print('URLs.baseUrl = $url');
    }
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
  static const String payments = '/payments';
  static const String gallery = '/gallery';
}
