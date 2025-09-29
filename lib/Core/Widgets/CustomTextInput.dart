import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';

class CustomTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget? iconWidget;
  final bool isRequired;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isEnabled;
  final int maxLines;
  final int minLines;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextInput({
    Key? key,
    required this.controller,
    required this.label,
    this.iconWidget,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.isEnabled = true,
    this.maxLines = 1,
    this.minLines = 1,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        enabled: isEnabled,
        cursorColor: ColorPalatte.primary,
        style: const TextStyle(height: 1),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        minLines: minLines,
        maxLines: maxLines,
        inputFormatters: inputFormatters ?? [],
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: Commonstyles.placeHolderText,
          prefixIcon: iconWidget,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: ColorPalatte.gray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: ColorPalatte.borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ColorPalatte.primary),
          ),
          counterText: '',
        ),
        validator: validator ??
            (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return '$label is required';
              }
              return null;
            },
        onChanged: onChanged,
      ),
    );
  }
}
