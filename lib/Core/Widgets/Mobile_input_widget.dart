import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';

import '../../Features/AuthDirectory/Login/LoginStyles.dart';
import '../Constants/ColorPalatte.dart';
import '../Constants/TextString.dart';

class MobileInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String initialCountryCode;
  final String? initialValue;
  final Function(String) onCountryChanged;
  final bool isRequired;
  final String label;
  final Color color;
  final bool enabled;
  final bool bottomBorderOnly;

  const MobileInputWidget({
    super.key,
    required this.controller,
    this.initialCountryCode = 'IN',
    this.initialValue,
    required this.onCountryChanged,
    this.isRequired = true,
    this.label = "",
    this.color = ColorPalatte.primary,
    this.enabled = true,
    this.bottomBorderOnly = false,
  });

  @override
  _MobileInputWidgetState createState() => _MobileInputWidgetState();
}

class _MobileInputWidgetState extends State<MobileInputWidget> {
  String selectedCountryCode = "";
  bool showValidationMessage = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
    }
    selectedCountryCode = widget.initialCountryCode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntlPhoneField(
          enabled: widget.enabled,
          controller: widget.controller,
          cursorColor: ColorPalatte.primary,
          decoration: LoginStyles.phoneInputDecoration.copyWith(
            labelText: widget.label.isNotEmpty
                ? widget.label
                : Textstring().phoneNumber,
            labelStyle: LoginStyles.phoneLabelStyle,
            floatingLabelStyle: Commonstyles.mobileNumberTextwithCountry,
            border: widget.bottomBorderOnly
                ? UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorPalatte.black),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ColorPalatte.black),
                  ),
            focusedBorder: widget.bottomBorderOnly
                ? const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ColorPalatte.primary, width: 2),
                  ),
            counterText: '',
          ),
          initialCountryCode: widget.initialCountryCode,
          onChanged: (phone) {
            setState(() {
              selectedCountryCode = phone.countryCode;
              showValidationMessage = phone.number.isEmpty;
            });
            widget.onCountryChanged(phone.countryCode);
          },
          onSubmitted: (value) {
            setState(() {
              showValidationMessage = value.isEmpty;
            });
          },
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (widget.isRequired && showValidationMessage)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              Textstring().loginPhonenumberisrequired,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
