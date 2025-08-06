import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';

class CustomDatePicker extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const CustomDatePicker({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );

    if (pickedDate != null) {
      setState(() {
        widget.controller.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: widget.controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(
            color: ColorPalatte.black,
          ),
          hintText: "Select Date",
          hintStyle: TextStyle(color: ColorPalatte.borderGray),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_month, color: ColorPalatte.primary),
            onPressed: () => _selectDate(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ColorPalatte.borderGray, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ColorPalatte.borderGray, width: 1),
          ),
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }
}
