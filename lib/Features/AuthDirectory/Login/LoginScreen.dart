import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Features/AuthDirectory/Login/LoginController.dart';
import 'package:tailorapp/Features/AuthDirectory/Login/LoginStyles.dart';
import 'package:tailorapp/Routes/App_route.dart';
import '../../../Core/Constants/TextString.dart';
import '../../../Core/Widgets/AccountNotFoundDialog.dart';
import '../../../Core/Widgets/CustomLoader.dart';
import '../../../Core/Widgets/Mobile_input_widget.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final Logincontroller _loginController = Logincontroller();
  String selectedCountryCode = "+91";

  void sendOtp() async {
    String mobileNumber = _loginController.phoneControllerLogin.text.trim();

    if (mobileNumber.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        Textstring().pleaseenteravalidphonenumber,
        duration: Duration(seconds: 1),
      );
      return;
    }

    if (_loginController.formKeyLogin.currentState?.validate() ?? false) {
      String fullMobileNumber = '91$mobileNumber';

      try {
        showLoader(context);
        final payload = {
          'mobileNumber': fullMobileNumber,
        };
        final response =
            await ApiService().post(data: payload, Urls.login, context);
        hideLoader(context);
        if (response.data['otp'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.otpVerification,
            arguments: {
              'mobileNumber': fullMobileNumber,
              'otp': response.data['otp'],
            },
          );
        } else {
          CustomSnackbar.showSnackbar(
            context,
            response.data['message'],
            duration: Duration(seconds: 1),
          );
        }
      } on DioException catch (e) {
        if (e.response?.data['error'] == "User not found") {
          hideLoader(context);
          showDialog(
            context: context,
            builder: (_) => AccountNotFoundDialog(
              mobileNumber: fullMobileNumber,
              onTryAgain: () => Navigator.pop(context),
              onNewShopRegister: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.registration);
              },
            ),
          );
        }
      }
    } else {
      CustomSnackbar.showSnackbar(
        context,
        Textstring().pleaseenteravalidphonenumber,
        duration: Duration(seconds: 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.phone_iphone,
                      size: 40, color: ColorPalatte.primary),
                ),
                SizedBox(height: 20),
                // Welcome text
                Text(
                  Textstring().welcomeback,
                  style: LoginStyles.welcomebackText,
                ),
                SizedBox(height: 5),
                Text(
                  Textstring().signintocontinue,
                  style: LoginStyles.signintocontinueText,
                ),
                SizedBox(height: 20),

                // Phone number input
                Form(
                  key: _loginController.formKeyLogin,
                  child: MobileInputWidget(
                    controller: _loginController.phoneControllerLogin,
                    initialCountryCode: 'IN',
                    onCountryChanged: (code) {
                      setState(() {
                        selectedCountryCode = code;
                      });
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Generate OTP button
                InkWell(
                  onTap: sendOtp,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ColorPalatte.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        Textstring().generateOtp,
                        style: LoginStyles.sendOtp.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Terms & Privacy Policy
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: Textstring().bycontinuingyouagreetoour,
                            style: LoginStyles.bycontinue,
                          ),
                          TextSpan(
                            text: Textstring().termsandservice,
                            style: LoginStyles.termsandcondition,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Navigator.pushNamed(context, AppRoutes.termsOfService);
                              },
                          ),
                          TextSpan(
                              text: Textstring().and,
                              style: LoginStyles.bycontinue),
                          TextSpan(
                            text: Textstring().privacyPolicy,
                            style: LoginStyles.termsandcondition,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Divider(color: ColorPalatte.gray, thickness: 0.5),

                SizedBox(height: 10),
                Text(
                  Textstring().wanttoregisteranewshop,
                  style: LoginStyles.wanttoregisteranewshopText,
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.registration);
                    },
                    icon: Icon(Icons.store, color: ColorPalatte.primary),
                    label: Text(
                      Textstring().newshopregistration,
                      style: TextStyle(color: ColorPalatte.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColorPalatte.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
