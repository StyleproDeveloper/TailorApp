import 'package:flutter/cupertino.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';

class DressStyle {
  static const TextStyle headerDress = TextStyle(
    fontFamily:Fonts.Medium,
    fontSize: 18,
    color:ColorPalatte.primary
  );
  static const TextStyle dressText = TextStyle(
    fontFamily:Fonts.Regular,
    fontSize: 14,
    color:ColorPalatte.primary
  );
  static const TextStyle measurementText = TextStyle(
    fontFamily:Fonts.Regular,
    fontSize: 14,
    color:ColorPalatte.black
  );
  static const TextStyle saveBtnDress = TextStyle(
    fontFamily:Fonts.Light,
    fontSize: 14,
    color:ColorPalatte.white
  );
}