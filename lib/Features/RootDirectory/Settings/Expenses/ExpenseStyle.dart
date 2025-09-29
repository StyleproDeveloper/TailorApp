import 'package:flutter/cupertino.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';

class Expensestyle {
  static const TextStyle headerExpense = TextStyle(
    fontFamily:Fonts.Medium,
    fontSize: 18,
    color:ColorPalatte.primary
  );
  static const TextStyle expenseText = TextStyle(
    fontFamily:Fonts.Regular,
    fontSize: 14,
    color:ColorPalatte.black
  );
  static const TextStyle saveBtnExpense = TextStyle(
    fontFamily:Fonts.Light,
    fontSize: 14,
    color:ColorPalatte.white
  );
}