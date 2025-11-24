class Urls {
  // HARDCODED LOCAL BACKEND - NO EXCEPTIONS
  static const String baseUrl = 'http://localhost:5500';
  
  // Log on first access
  static String get baseUrlGetter {
    print('🚨🚨🚨 URLS.BASEURL = http://localhost:5500 🚨🚨🚨');
    return baseUrl;
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
