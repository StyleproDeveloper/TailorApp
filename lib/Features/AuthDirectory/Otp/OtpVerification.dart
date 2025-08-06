import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/AuthDirectory/Otp/OtpStyles.dart';
import 'package:tailorapp/Features/AuthDirectory/Otp/OtpInputWidget.dart';
import 'package:tailorapp/Features/AuthDirectory/Otp/OtpVerificationController.dart';

import '../../../Core/Widgets/CustomSnakBar.dart';

class OtpVerificationScreen extends StatefulWidget {
  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final OtpVerificationController _controller = OtpVerificationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null &&
          args.containsKey('mobileNumber') &&
          args.containsKey('otp')) {
        String mobileNumber = args['mobileNumber'];
        String otp = args['otp'].toString();
        _controller.initialize(context, mobileNumber);

        CustomSnackbar.showSnackbar(context, "Your OTP is: $otp",
            duration: Duration(seconds: 2));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        body: Center(child: Text("No data received")),
      );
    }
    final String mobileNumber = args['mobileNumber'];

    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(title: Textstring().back),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.phone_iphone,
                      size: 40, color: ColorPalatte.primary),
                ),
                SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Textstring().verifyPhoneNumber,
                      style: Otpstyles.verifyHeaderText,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "${Textstring().checkyourSMSmessagesWevesentyouthePINatm} $mobileNumber.",
                      textAlign: TextAlign.center,
                      style: Otpstyles.checkSMStext,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (index) => OtpInputWidget(
                          index: index,
                          controller: _controller.controllers[index],
                          focusNode: _controller.focusNodes[index],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 3) {
                                FocusScope.of(context).requestFocus(
                                    _controller.focusNodes[index + 1]);
                              } else {
                                _controller.focusNodes[index].unfocus();
                              }
                            } else if (value.isEmpty && index > 0) {
                              FocusScope.of(context).requestFocus(
                                  _controller.focusNodes[index - 1]);
                            }
                            _controller.onOtpChanged();
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Textstring().didntreceiveSMS,
                          style: Otpstyles.didnotrecievesms,
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _controller.start,
                          builder: (context, value, child) {
                            return value > 0
                                ? Row(
                                    children: [
                                      SizedBox(width: 5),
                                      Text(
                                        "00:$value",
                                        style: TextStyle(
                                          color: ColorPalatte.primary,
                                          fontFamily: Fonts.Medium,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  )
                                : SizedBox.shrink();
                          },
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _controller.showResendButton,
                          builder: (context, show, child) {
                            return show
                                ? TextButton(
                                    onPressed: _controller.resendOtp,
                                    child: Text(
                                      Textstring().resend,
                                      style: Otpstyles.resendBtn,
                                    ),
                                  )
                                : SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        String otp =
                            _controller.controllers.map((c) => c.text).join('');
                        _controller.login(otp);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: ColorPalatte.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        Textstring().verify,
                        style: Otpstyles.verifyText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Otpstyles.didnotrecievesms,
                    children: [
                      TextSpan(
                        text: Textstring().havingtrouble,
                      ),
                      TextSpan(
                        text: " ${Textstring().contactsupport}",
                        style: Otpstyles.contactsupportText,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle contact support tap action
                          },
                      ),
                    ],
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
