import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';

class LoginStyles {
  // Text Styles

  static const TextStyle welcomebackText = TextStyle(
      color: ColorPalatte.black, fontSize: 22, fontFamily: Fonts.Bold);

  static const TextStyle signintocontinueText = TextStyle(
      color: ColorPalatte.black, fontSize: 14, fontFamily: Fonts.Light);

  static const TextStyle phoneLabelStyle = TextStyle(
      color: ColorPalatte.gray, fontSize: 14, fontFamily: Fonts.Medium);

  static const TextStyle wanttoregisteranewshopText = TextStyle(
      color: ColorPalatte.black, fontSize: 14, fontFamily: Fonts.Light);

      static const TextStyle termsandcondition = TextStyle(
      color: ColorPalatte.primary, fontSize: 14, fontFamily: Fonts.Regular);

      static const TextStyle bycontinue = TextStyle(
      color: ColorPalatte.black, fontSize: 14, fontFamily: Fonts.Regular);

  static const TextStyle sendOtp = TextStyle(
    color: ColorPalatte.white,
    fontSize: 16,
    fontFamily: Fonts.Bold
  );

  // Input Decoration
  static InputDecoration phoneInputDecoration = InputDecoration(
    hintText: Textstring().phoneNumber, // Replace with dynamic text if needed
    border: OutlineInputBorder(),
    hintStyle: TextStyle(color: Colors.grey, fontFamily: Fonts.Medium),
  );

  // Other Alignments
  static const MainAxisAlignment mainAxisAlignmentCenter =
      MainAxisAlignment.center;
}
