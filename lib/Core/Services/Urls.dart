import 'dart:html' as html;

class Urls {
  // Backend URL - automatically detects environment
  static String get baseUrl {
    // Check if running in browser
    try {
      final hostname = html.window.location.hostname;
      
      // If running on localhost or 127.0.0.1, use local backend
      if (hostname == 'localhost' || hostname == '127.0.0.1') {
        return 'http://localhost:5500';
      }
      
      // Otherwise, use production backend (Vercel)
      return 'https://backend-m5vayhncz-stylepros-projects.vercel.app';
    } catch (e) {
      // Fallback: if window is not available, default to production
      return 'https://backend-m5vayhncz-stylepros-projects.vercel.app';
    }
  }
  
  // Alternative Vercel URLs (if main URL has issues)
  // static const String baseUrl = 'https://backend-oh2r1ys5u-stylepros-projects.vercel.app';
  // static const String baseUrl = 'https://backend-ohnwrg4uj-stylepros-projects.vercel.app';
  
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
  static const String billingTerm = '/billing-term';
  static const String userBranch = '/user-branch';
  static const String shopSetupComplete = '/shops/setup-complete';
}
