import 'dart:html' as html;

class Urls {
  // Backend URL - automatically detects environment
  static String get baseUrl {
    // Check if running in browser
    try {
      final hostname = html.window.location.hostname;
      final protocol = html.window.location.protocol;
      
      print('🌐 Detected hostname: $hostname');
      print('🌐 Detected protocol: $protocol');
      
      // If running on localhost or 127.0.0.1, use local backend
      if (hostname == 'localhost' || hostname == '127.0.0.1') {
        final url = 'http://localhost:5500';
        print('✅ Using LOCAL backend: $url');
        return url;
      }
      
      // Otherwise, use production backend (Vercel)
      final url = 'https://backend-pics4hvfk-stylepros-projects.vercel.app';
      print('✅ Using PRODUCTION backend: $url');
      return url;
    } catch (e) {
      // Fallback: if window is not available, default to production
      print('⚠️ Error detecting hostname, using production backend');
      return 'https://backend-pics4hvfk-stylepros-projects.vercel.app';
    }
  }
  
  // Alternative Vercel URLs (if main URL has issues)
  // static const String baseUrl = 'https://backend-m5vayhncz-stylepros-projects.vercel.app';
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
