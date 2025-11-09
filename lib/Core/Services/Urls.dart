class Urls {
  // Production backend URL - Vercel deployment
  // static const String baseUrl = 'https://backend-m5vayhncz-stylepros-projects.vercel.app';
  
  // Development backend URL (for local development)
  static const String baseUrl = 'http://localhost:5500';
  
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