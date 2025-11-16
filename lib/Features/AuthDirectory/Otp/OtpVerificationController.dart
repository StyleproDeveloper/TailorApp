import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Routes/App_route.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';

import '../../../GlobalVariables.dart';

class OtpVerificationController {
  final List<TextEditingController> controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  final ValueNotifier<int> start = ValueNotifier<int>(30); // Countdown timer
  final ValueNotifier<bool> showResendButton =
      ValueNotifier<bool>(false); // Initially, "Resend OTP" is hidden

  Timer? timer;
  late BuildContext context;
  String mobileNumber = ""; // Store the mobile number for resend OTP

  void initialize(BuildContext ctx, String phone) {
    context = ctx;
    mobileNumber = phone;
    startTimer(); // Start timer when the screen loads
  }

  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    timer?.cancel();
    start.dispose();
    showResendButton.dispose();
  }

  void onOtpChanged() {
    String otp = controllers.map((c) => c.text).join('');
    if (otp.length == 4) {
      login(otp);
    }
  }

  Future<void> login(String otp) async {
    if (otp.isEmpty || otp.length < 4) {
      CustomSnackbar.showSnackbar(context, "Please enter a valid OTP.",
          duration: Duration(seconds: 1));
      return;
    }
    try {
      final payload = {"mobileNumber": mobileNumber, "otp": otp};
      final response = await ApiService().post(Urls.otpVerify, data: payload, context);
      print('object response::::::::: ${response.data}');
      if (response.data != null &&
          response.data['user'] != null &&
          response.data['user']['userId'] != null) {
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString(Textstring().tokenId, response.data['user']['id']);
        await pref.setInt(Textstring().shopId, response.data['user']['shopId']);
        await pref.setInt(Textstring().userId, response.data['user']['userId']);
        await pref.setInt(
            Textstring().branchId, response.data['user']['branchId']);
        await GlobalVariables.loadShopId();

        // Debug: Print full response to check subscription status
        print('🔍 Full login response: ${response.data}');
        print('🔍 Subscription Status: ${response.data['subscriptionStatus']}');

        CustomSnackbar.showSnackbar(context, response.data['message'],
            duration: Duration(seconds: 1));

        // Check if trial has expired and subscription is required
        final subscriptionStatus = response.data['subscriptionStatus'];
        print('🔍 Subscription Status object: $subscriptionStatus');
        
        if (subscriptionStatus != null) {
          print('🔍 requiresSubscription value: ${subscriptionStatus['requiresSubscription']}');
          print('🔍 isTrialExpired value: ${subscriptionStatus['isTrialExpired']}');
          print('🔍 subscriptionType value: ${subscriptionStatus['subscriptionType']}');
        } else {
          print('⚠️ Subscription Status is null!');
        }
        
        final requiresSubscription = subscriptionStatus != null && 
            subscriptionStatus['requiresSubscription'] == true;
        
        print('🔍 Final requiresSubscription check: $requiresSubscription');

        Future.delayed(Duration(milliseconds: 500), () {
          if (requiresSubscription) {
            print('✅ Redirecting to subscribe page');
            // Redirect to subscribe page if trial expired
            Navigator.pushReplacementNamed(context, AppRoutes.subscribe);
          } else {
            print('✅ Redirecting to home page');
            // Normal login flow
            Navigator.pushReplacementNamed(context, AppRoutes.homeUi);
          }
        });
      } else {
        CustomSnackbar.showSnackbar(context, Textstring().invalidOTP,
            duration: Duration(seconds: 1));
      }
    } catch (e) {
      print("Error: $e");
      
    }
  }

  void startTimer() {
    timer?.cancel();
    start.value = 30;
    showResendButton.value = false;

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (start.value == 0) {
        timer.cancel();
        showResendButton.value = true;
      } else {
        start.value--;
      }
    });
  }

  Future<void> resendOtp() async {
    print("Resend OTP clicked for $mobileNumber");

    // try {
    //   final payload = {"mobile": mobileNumber}; // API expects just the phone number
    //   final response = await ApiService().post(Urls.baseUrl, data: payload);

    //   if (response.data == true) {
    //     CustomSnackbar.showSnackbar(context, "OTP has been resent.",
    //         duration: Duration(seconds: 1));
    //     startTimer(); // Restart countdown
    //   } else {
    //     CustomSnackbar.showSnackbar(context, "Failed to resend OTP.",
    //         duration: Duration(seconds: 1));
    //   }
    // } catch (e) {
    //   print("Error: $e");
    //   CustomSnackbar.showSnackbar(context, "Error sending OTP. Try again!",
    //       duration: Duration(seconds: 1));
    // }
  }
}
