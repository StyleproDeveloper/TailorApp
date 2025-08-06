import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';

class Commonstyles {
  static const TextStyle headerText = TextStyle(
      fontFamily: Fonts.Medium, fontSize: 18, color: ColorPalatte.black);
  static const TextStyle snackBarText = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: Fonts.Light,
  );
  static const TextStyle mobileNumberTextwithCountry = TextStyle(
    color: ColorPalatte.gray,
    fontSize: 16,
    fontFamily: Fonts.Medium,
  );
  static const TextStyle headerTextblack = TextStyle(
      fontFamily: Fonts.Bold, fontSize: 18, color: ColorPalatte.black);
  static const TextStyle accountNotFoundSbbText = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontFamily: Fonts.Light,
  );
  static const TextStyle placeHolderText = TextStyle(
      color: ColorPalatte.gray, fontFamily: Fonts.Regular, fontSize: 14);
  static const TextStyle alertTitle = TextStyle(
      color: ColorPalatte.black, fontFamily: Fonts.Bold, fontSize: 17);
  static const TextStyle alertSubtitle = TextStyle(
      color: ColorPalatte.black, fontFamily: Fonts.Regular, fontSize: 14);
  static const TextStyle alertCancel = TextStyle(
      color: ColorPalatte.black, fontFamily: Fonts.Medium, fontSize: 13);
  static const TextStyle alertSubmit = TextStyle(
      color: ColorPalatte.white, fontFamily: Fonts.Medium, fontSize: 13);
}
