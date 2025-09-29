import 'package:flutter/cupertino.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';

class Rolestyle {
  static const TextStyle headerRole = TextStyle(
    fontFamily:Fonts.Medium,
    fontSize: 18,
    color:ColorPalatte.primary
  );
  static const TextStyle roleNameLabel = TextStyle(
    fontFamily:Fonts.Regular,
    fontSize: 14,
    color:ColorPalatte.black
  );
  static const TextStyle saveBtnRole = TextStyle(
    fontFamily:Fonts.Light,
    fontSize: 14,
    color:ColorPalatte.white
  );
}