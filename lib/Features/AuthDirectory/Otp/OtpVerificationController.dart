import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Routes/App_route.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';

import '../../../GlobalVariables.dart';
import 'package:tailorapp/Core/Services/PermissionService.dart';

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
        
        // Save role permissions
        final userData = response.data['user'];
        print('🔍 User data keys: ${userData.keys.toList()}');
        print('🔍 roleId: ${userData['roleId']}');
        print('🔍 roleName: ${userData['roleName']}');
        print('🔍 rolePermissions: ${userData['rolePermissions']}');
        print('🔍 Full userData: $userData');
        
        // ALWAYS save and load permissions, even if empty
        print('🔍🔍🔍 LOGIN: Starting permission save process');
        print('🔍🔍🔍 userData keys: ${userData.keys.toList()}');
        print('🔍🔍🔍 roleId: ${userData['roleId']}');
        print('🔍🔍🔍 rolePermissions: ${userData['rolePermissions']}');
        
        // CRITICAL: Always save permissions, even if roleId is null (will save empty map)
        final rolePermissions = userData['rolePermissions'] ?? {};
        final roleId = userData['roleId'];
        final roleName = userData['roleName'];
        
        print('🔍🔍🔍 LOGIN: Saving permissions');
        print('🔍🔍🔍 roleId: $roleId');
        print('🔍🔍🔍 roleName: $roleName');
        print('🔍🔍🔍 rolePermissions type: ${rolePermissions.runtimeType}');
        print('🔍🔍🔍 rolePermissions: $rolePermissions');
        print('🔍🔍🔍 rolePermissions keys: ${rolePermissions.keys.toList()}');
        
        // Convert to Map<String, dynamic> to ensure proper type
        final permissionsMap = <String, dynamic>{};
        if (rolePermissions is Map) {
          rolePermissions.forEach((key, value) {
            permissionsMap[key.toString()] = value;
          });
        }
        
        print('🔍🔍🔍 Converted permissions map: $permissionsMap');
        print('🔍🔍🔍 Permissions map count: ${permissionsMap.length}');
        
        // CRITICAL: Always save, even if empty - this helps us debug
        await PermissionService.savePermissions(
          roleId: roleId ?? 0,
          roleName: roleName,
          permissions: permissionsMap,
        );
        
        if (permissionsMap.isEmpty) {
          print('⚠️⚠️⚠️ WARNING: Permissions map is EMPTY!');
          print('⚠️⚠️⚠️ This means role-based access will NOT work!');
          print('⚠️⚠️⚠️ Check backend logs to see if role was found in database');
        } else {
          print('✅✅✅ Permissions saved to SharedPreferences');
        }
        
        // Verify permissions were saved - CRITICAL CHECK
        final savedPermissions = await PermissionService.loadPermissions();
        print('✅✅✅ Verified saved permissions: $savedPermissions');
        print('✅✅✅ Saved permissions count: ${savedPermissions.length}');
        if (savedPermissions.isNotEmpty) {
          print('✅✅✅ Sample permissions:');
          savedPermissions.forEach((key, value) {
            print('  - $key: $value');
          });
        } else {
          print('⚠️⚠️⚠️ WARNING: No permissions were saved!');
        }
        
        // Load into GlobalVariables immediately - CRITICAL
        await GlobalVariables.loadShopId();
        
        // Debug: Print loaded permissions
        print('🔍🔍🔍 GlobalVariables permissions after load: ${GlobalVariables.permissions}');
        print('🔍🔍🔍 GlobalVariables permissions count: ${GlobalVariables.permissions.length}');
        print('🔍🔍🔍 GlobalVariables roleId: ${GlobalVariables.roleId}');
        print('🔍🔍🔍 GlobalVariables roleName: ${GlobalVariables.roleName}');
        
        // CRITICAL: Verify permissions are actually in GlobalVariables
        if (GlobalVariables.permissions.isEmpty) {
          print('❌❌❌ ERROR: Permissions are empty in GlobalVariables after load!');
          print('❌❌❌ This means role-based access will NOT work!');
        } else {
          print('✅✅✅ SUCCESS: Permissions loaded into GlobalVariables');
          print('✅✅✅ Role-based access should work correctly');
        }

        // Debug: Print full response to check subscription status
        print('🔍 Full login response: ${response.data}');
        print('🔍 Subscription Status: ${response.data['subscriptionStatus']}');

        // Save subscription data to GlobalVariables
        final subscriptionStatus = response.data['subscriptionStatus'];
        if (subscriptionStatus != null) {
          await GlobalVariables.updateSubscriptionData(
            subscriptionStatus['subscriptionType']?.toString(),
            subscriptionStatus['trialEndDate']?.toString(),
          );
        }

        CustomSnackbar.showSnackbar(context, response.data['message'],
            duration: Duration(seconds: 1));

        // Check if trial has expired and subscription is required
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
