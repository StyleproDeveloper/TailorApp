import 'package:flutter/material.dart';
import 'package:tailorapp/Features/AuthDirectory/Login/LoginScreen.dart';
import 'package:tailorapp/Features/AuthDirectory/Otp/OtpVerification.dart';
import 'package:tailorapp/Features/AuthDirectory/SignUp/RegisterScreen.dart';
import 'package:tailorapp/Features/AuthDirectory/SignUp/RegistrationSuccessScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/OrderDetail/OrderDetailsScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/BillingTerms/billing_details_screen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Branches/BranchesScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Shop/ShopDetailsScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/contactUs/ContactSupportScreen.dart';
import 'package:tailorapp/Features/RootDirectory/customer/CustomerInfo.dart';
import 'package:tailorapp/Features/RootDirectory/BottomTabs/BottomTabs.dart';
import 'package:tailorapp/Features/AuthDirectory/Subscribe/SubscribeScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/CreateOrder/CreateOrderScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Dress/Dress_screen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Expenses/ExpenseScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Roles/RoleScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/User/UserScreen.dart';
import 'package:tailorapp/Features/RootDirectory/customer/CustomerScreen.dart';
import 'package:tailorapp/Features/Splash/SplashScreen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otpVerification = '/OtpVerification';
  static const String homeUi = '/HomeUI';
  static const String home = '/'; // Add root route
  static const String registration = './Registerscreen';
  static const String customerInfo = './CustomerInfo';
  static const String userScreen = './Userscreen';
  static const String roleScreen = './Rolescreen';
  static const String expenses = './ExpenseScreen';
  static const String dressScreen = './DressScreen';
  static const String shopBranches = './shopBranches';
  static const String createOrder = './createOrder';
  static const String customerScreen = './customerScreen';
  static const String contactSupportScreen = './contactSupportScreen';
  static const String billingTermsScreen = './billingTermsScreen';
  static const String orderDetailsScreen = './orderDetailsScreen';
  static const String shopDetailsScreen = './shopDetailsScreen';
  static const String registrationSuccess = './registrationSuccess';
  static const String subscribe = './subscribe';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const Splashscreen(), // Root route redirects to splash
    splash: (context) => const Splashscreen(),
    login: (context) => const Loginscreen(),
    otpVerification: (context) => OtpVerificationScreen(),
    registration: (context) => RegisterScreen(),
    homeUi: (context) => Homescreen(),
    customerInfo: (context) => Customerinfo(),
    userScreen: (context) => Userscreen(),
    roleScreen: (context) => Rolescreen(),
    expenses: (context) => Expensescreen(),
    dressScreen: (context) => DressScreen(),
    shopBranches: (context) => BranchesScreen(),
    createOrder: (context) => CreateOrderScreen(),
    customerScreen: (context) => Customerscreen(),
    contactSupportScreen: (context) => ContactSupportScreen(),
    billingTermsScreen: (context) => BillingDetailsScreen(),
    orderDetailsScreen: (context) => OrderDetailsScreen(),
    shopDetailsScreen: (context) => ShopDetailsScreen(),
    registrationSuccess: (context) => const RegistrationSuccessScreen(),
    subscribe: (context) => const SubscribeScreen(),
  };
}