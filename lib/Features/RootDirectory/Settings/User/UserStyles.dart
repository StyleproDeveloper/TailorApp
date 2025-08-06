import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';

class Userstyles {
  static const TextStyle addUserText = TextStyle(
    fontFamily: Fonts.Medium,
    fontSize: 18,
    color: ColorPalatte.primary
  );
  static const TextStyle adduserTextplus = TextStyle(
    color: ColorPalatte.primary, fontFamily: Fonts.Regular, fontSize: 14
  );
   static const TextStyle fullnameLable = TextStyle(
    fontFamily: Fonts.Regular,
    fontSize: 14,
    color: ColorPalatte.black
  );
  static const TextStyle viewPermission = TextStyle(
    fontFamily: Fonts.Medium,
    fontSize: 16,
    color: ColorPalatte.black
  );
  static const TextStyle permission = TextStyle(
    fontFamily: Fonts.Bold,
    fontSize: 14,
    color: ColorPalatte.white
  );
  static const TextStyle saveUserText = TextStyle(
    fontFamily: Fonts.Light,
    fontSize: 14,
    color: ColorPalatte.white
  );
  static const TextStyle listPermissions = TextStyle(
    fontFamily: Fonts.Light,
    fontSize: 14,
    color: ColorPalatte.black
  );
}