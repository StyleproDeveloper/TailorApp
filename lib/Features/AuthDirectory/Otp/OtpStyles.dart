import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';

class Otpstyles {
  static const TextStyle verifyHeaderText = TextStyle(
    fontFamily: Fonts.Bold,
    fontSize: 20,
    color: ColorPalatte.black
  );
  static const TextStyle checkSMStext = TextStyle(
    fontFamily: Fonts.Regular,
    fontSize: 16,
    color: Colors.grey
  );
  static const TextStyle didnotrecievesms = TextStyle(
    fontFamily: Fonts.Regular,
    fontSize: 14,
    color: ColorPalatte.black
  );
  static const TextStyle contactsupportText = TextStyle(
    fontFamily: Fonts.Regular,
    fontSize: 14,
    color: ColorPalatte.primary
  );
  static const TextStyle resendBtn = TextStyle(
    fontFamily: Fonts.Bold,
    fontSize: 14,
    color: ColorPalatte.primary
  );
  static const TextStyle verifyText = TextStyle(
    fontFamily: Fonts.Bold,
    fontSize: 16,
    color: ColorPalatte.white
  );
}