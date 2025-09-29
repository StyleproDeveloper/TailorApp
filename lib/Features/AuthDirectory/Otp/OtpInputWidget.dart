import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';

class OtpInputWidget extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function onChanged;

  OtpInputWidget({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 58,
      margin: EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        cursorColor: ColorPalatte.primary,
        cursorHeight: 20,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ColorPalatte.primary,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(15),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: ColorPalatte.black, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: ColorPalatte.primary, width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => onChanged(value),
      ),
    );
  }
}
